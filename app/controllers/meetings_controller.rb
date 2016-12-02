# Join a meeting
class MeetingsController < ApplicationController
  rescue_from Room::ValidationFailed,  with: :room_error
  rescue_from SlackApi::NotAuthorized, with: :not_authorized

  before_action :channel_exists!
  before_action :authorized!
  before_action :user_or_session!
  before_action :user_belongs_to_team!

  def show
    room = Room.new(channel: @channel, user: @user)

    slack_api = SlackApi.new(@user.access_token)
    slack_api.request('/chat.postMessage',
                      channel: @channel.external_id,
                      as_user: true,
                      text:    I18n.t('.joined',
                                      url: meeting_url(id: params[:id]),
                                      scope: [:meetings, :show]))

    redirect_to room.url
  end

  private

  def channel_exists!
    @channel = Channel.find_by(external_id: params[:id])
    return if @channel.present?
    redirect_to :setup
  end

  def authorized!
    @user = User.find_by(id: session[@channel.team_id.to_s])
  end

  def user_or_session!
    return if @user.present? ||
              session[:state].present? &&
              session[:state] == params[:state]
    not_authorized
  end

  def user_belongs_to_team!
    return if @user.present? && @user.team_id == @channel.team_id
    redirect_to Rails.configuration.services['help_page']
  end

  def room_error(e)
    render json: { error: e }, status: :bad_request
  end

  def not_authorized
    state = SecureRandom.hex(5)
    redirect_to login_path(
      redirect_uri: meeting_path(id: params[:id], state: state),
      state:        state
    )
  end
end

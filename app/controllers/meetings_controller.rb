# Join a meeting
class MeetingsController < ApplicationController
  rescue_from Room::ValidationFailed,  with: :room_error
  rescue_from SlackApi::NotAuthorized, with: :slack_not_authorized

  before_action :authorized!
  before_action :channel_exists!
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

  def authorized!
    @user = User.find_by(id: session[:user_id])
    return if @user.present?
    redirect_to login_path(
      redirect_uri: meeting_path(id: params[:id])
    )
  end

  def channel_exists!
    @channel = Channel.find_by(external_id: params[:id])
    return if @channel.present?
    redirect_to :setup
  end

  def user_belongs_to_team!
    return if @user.team_id == @channel.team_id
    # TODO: raise an error
    redirect_to login_path(redirect_uri: meeting_path(id: params[:id]))
  end

  def room_error(e)
    render json: { error: e }, status: :bad_request
  end

  def slack_not_authorized
    redirect_to login_path(redirect_uri: meeting_path(id: params[:id]))
  end
end

# Join a meeting
class MeetingsController < ApplicationController
  rescue_from Room::ValidationFailed,  with: :room_error
  rescue_from SlackApi::RequestFailed, with: :slack_failed
  rescue_from SlackApi::MissingScope, with: :missing_scope

  before_action :channel_exists!
  before_action :authorized!
  before_action :user_belongs_to_team!

  def show
    @room = Room.new(channel: @channel, user: @user)

    slack_api = SlackApi.new(@user.access_token)
    slack_api.request('/chat.postMessage',
                      channel: @channel.external_id,
                      as_user: true,
                      text:    I18n.t('.joined',
                                      url: meeting_url(id: params[:id]),
                                      scope: [:meetings, :show]))

    redirect_to @room.url
  end

  private

  def channel_exists!
    @channel = Channel.find_by(external_id: params[:id])
    return if @channel.present?
    redirect_to Rails.configuration.services['help_page']
  end

  def authorized!
    @user = User.find_by(id: params[:user_id])
    return if @user.present?
    redirect_to login_path(
      redirect_uri: meeting_path(id: params[:id])
    )
  end

  def user_belongs_to_team!
    return if @user.team_id == @channel.team_id
    redirect_to Rails.configuration.services['help_page']
  end

  def room_error(e)
    render json: { error: e }, status: :bad_request
  end

  def slack_failed
    redirect_to @room.url
  end

  def missing_scope
    redirect_to login_path(
      redirect_uri: meeting_path(id: params[:id]),
      scope:        'chat:write:user'
    )
  end
end

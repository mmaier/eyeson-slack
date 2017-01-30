# Join a meeting
class MeetingsController < ApplicationController
  rescue_from Room::ValidationFailed,  with: :room_error
  rescue_from SlackApi::MissingScope,  with: :missing_scope
  rescue_from SlackApi::RequestFailed, with: :enter_room

  before_action :authorized!
  before_action :channel_exists!
  before_action :user_belongs_to_team!
  before_action :scope_required!
  before_action :ip_address

  def show
    @room = Room.new(channel: @channel, user: @user)

    slack_api = SlackApi.new(@user.access_token)
    slack_api.request('/chat.postMessage',
                      channel: @channel.external_id,
                      as_user: true,
                      text:    I18n.t('.joined',
                                      url: meeting_url(id: params[:id]),
                                      scope: [:meetings, :show]))

    enter_room
  end

  private

  def authorized!
    @user = User.find_by(id: params[:user_id])
    return if @user.present?
    redirect_to login_path(
      redirect_uri: meeting_path(id: params[:id])
    )
  end

  def channel_exists!
    @channel = Channel.find_by(external_id: params[:id])
    return if @channel.present?
    redirect_to @user.team.url
  end

  def user_belongs_to_team!
    return if @user.team_id == @channel.team_id
    redirect_to @channel.team.url
  end

  def scope_required!
    @user.scope_required!(%w(chat:write:user))
  end

  def ip_address
    ip = request.env['HTTP_X_FORWARDED_FOR']
    @user.ip_address = ip.split(",").first if ip.present?
  end

  def room_error(e)
    render json: { error: e }, status: :bad_request
  end

  def enter_room
    redirect_to @room.url
  end

  def missing_scope(scope)
    redirect_to login_path(
      redirect_uri: meeting_path(id: params[:id]),
      scope:        scope
    )
  end
end

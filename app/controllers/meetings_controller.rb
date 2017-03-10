# Join a meeting
class MeetingsController < ApplicationController
  rescue_from Eyeson::Room::ValidationFailed, with: :room_error
  rescue_from SlackApi::MissingScope,  with: :missing_scope
  rescue_from SlackApi::RequestFailed, with: :enter_room

  before_action :authorized!
  # before_action :user_confirmed!
  before_action :channel_exists!
  before_action :user_belongs_to_team!
  before_action :scope_required!

  def show
    Eyeson.configuration.api_key = @user.team.api_key

    @room = Eyeson::Room.join(id: @channel.external_id,
                              name: @channel.name,
                              user: @user)
    post_to_slack
    update_intercom
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

  def user_confirmed!
    return if @user.confirmed?
    account = Eyeson::Account.find_by(email: @user.email)
    if account.present?
      @user.confirmed = true
      @user.save
    else
      redirect_to account.confirmation_url
    end
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
    @user.scope_required!(%w(chat:write:user files:write:user))
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

  def post_to_slack
    @slack_api = SlackApi.new(@user.access_token)
    if @channel.new_command?
      post_open_info
    else
      post_join_info
    end
  end

  def post_open_info
    message = @slack_api.post_message!(
      channel: @channel.external_id,
      text:    I18n.t('.opened', url: meeting_url(id: params[:id]),
                                 scope: [:meetings, :show])
    )
    @channel.thread_id = message['ts']
    @channel.save
  end

  def post_join_info
    @slack_api.post_message!(
      channel: @channel.external_id,
      thread_ts: @channel.thread_id,
      text:    I18n.t('.joined', scope: [:meetings, :show])
    )
  end

  def update_intercom
    Eyeson::Intercom.post(email: @user.email,
                          ref: 'VIDEOMEETING',
                          fields: {
                            name: @user.name,
                            last_seen_ip: request.remote_ip
                          },
                          event: intercom_event)
  end

  def intercom_event
    {
      type: 'videomeeting_slack',
      data: {
        team: @user.team.name
      }
    }
  end
end

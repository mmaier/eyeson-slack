# Join a meeting
class MeetingsController < ApplicationController
  rescue_from Eyeson::Room::ValidationFailed, with: :room_error
  rescue_from SlackApi::MissingScope,  with: :missing_scope
  rescue_from SlackApi::RequestFailed, with: :enter_room

  before_action :authorized!
  before_action :user_confirmed!
  before_action :channel_exists!
  before_action :user_belongs_to_team!
  before_action :scope_required!
  after_action  :clear_access_key

  def show
    @channel.initializer_id = @user.id if @channel.thread_id.blank?

    @room = Eyeson::Room.join(id: @channel.external_id,
                              name: "##{@channel.name}",
                              user: @user)

    SlackNotificationService.new(@user.access_token, @channel).start

    update_intercom
    enter_room
  end

  private

  def authorized!
    @user = User.find_by(id: params[:user_id])
    return if @user.present?
    redirect_to login_path(
      redirect_uri: request.path
    )
  end

  def user_confirmed!
    return if @user.confirmed?
    account = Eyeson::Account.find_or_initialize_by(user: @user)
    if account.new_record?
      url = account.confirmation_url
      url += (url.include?('?') ? '&' : '?')
      redirect_to url + 'callback_url=' + request.original_url
    else
      @user.confirmed = true
      @user.save
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
    @user.scope_required!(SlackApi::DEFAULT_SCOPE)
  end

  def room_error(e)
    render json: { error: e }, status: :bad_request
  end

  def enter_room
    redirect_to @room.url
  end

  def missing_scope(scope)
    redirect_to login_path(
      redirect_uri: request.path,
      scope:        scope
    )
  end

  def update_intercom
    Eyeson::Intercom.post(email: @user.email,
                          ref: 'Slack',
                          fields: {
                            last_seen_ip: request.remote_ip
                          },
                          event: intercom_event)
  end

  def intercom_event
    { type: 'videomeeting_slack',
      data: { team: @user.team.name } }
  end

  def clear_access_key
    return unless @channel.webinar_mode?
    @channel.update access_key: nil
  end
end

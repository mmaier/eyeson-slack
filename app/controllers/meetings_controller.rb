# Join a meeting
class MeetingsController < ApplicationController
  rescue_from Eyeson::Room::ValidationFailed, with: :room_error
  rescue_from SlackApi::MissingScope,  with: :missing_scope
  rescue_from SlackApi::RequestFailed, with: :enter_room

  before_action :authorized!
  before_action :channel_exists!
  before_action :user_belongs_to_team!
  before_action :scope_required!

  def show
    @room = Eyeson::Room.join(id: @channel.external_id,
                              name: "##{@channel.name}",
                              user: @user.mapped)

    SlackNotificationService.new(@user.access_token, @channel).start

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
    scope = if @channel.webinar_mode?
              SlackApi::WEBINAR_SCOPE
            else
              SlackApi::DEFAULT_SCOPE
            end
    @user.scope_required!(scope)
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
end

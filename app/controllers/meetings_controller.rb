# Join a meeting
class MeetingsController < ApplicationController
  rescue_from Room::ValidationFailed, with: :room_error

  before_action :authorized!
  before_action :channel_exists!
  before_action :user_belongs_to_team!

  def show
    room = Room.new(channel: @channel, user: @user)

    # TODO: @channel.send_join_state!
    redirect_to room.url
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
    redirect_to :setup
  end

  def user_belongs_to_team!
    return if @user.team_id == @channel.team_id
    if @user.access_token.present?
      slack_api = SlackApi.new(@user.access_token)
      slack_api.get('/auth.revoke')
    end
    redirect_to login_path(redirect_uri: meeting_path(id: params[:id]))
  end

  def room_error(e)
    render json: { error: e }, status: :bad_request
  end
end

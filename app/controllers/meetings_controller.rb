# Join a meeting
class MeetingsController < ApplicationController
  before_action :valid_channel!
  before_action :authorized_or_leave!

  def show
    # Add user to conference room and redirect to communication GUI
    room = Room.new(channel: @channel, user: @user)

    if room.error.present?
      render json: { error: room.error }, status: :bad_request
    else
      redirect_to room.url
    end
  end

  private

  def valid_channel!
    @channel = Channel.find_by(external_id: params[:id])
    return if @channel.present?
    # TODO: Redirect to eyeson/slack info page
    render json: { error: 'Channel not found' }, status: :not_found
  end

  def authorized_or_leave!
    @user = User.find_by(team_id: @channel.team_id, id: params[:user_id])
    return if @user.present?
    redirect_to login_path(redirect_uri: meeting_path(id: params[:id]))
  end
end

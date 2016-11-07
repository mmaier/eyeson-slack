# Join a meeting
class MeetingsController < ApplicationController
  before_action :authorized_or_leave!
  before_action :oauth_client
  before_action :optain_user

  def show
    # Add user to conference room and redirect to communication GUI
    channel = {
      id:   params.require(:channel_id),
      name: params.require(:channel_name)
    }
    room = Room.new(channel: channel, user: @user)

    redirect_to room.url
  end

  private

  def authorized_or_leave!
    return if session[:access_token].present?
    redirect_to login_path(redirect_uri: meeting_path(id: params[:id]))
  end

  def optain_user
    # Optain profile from slack
    identity = JSON.parse(
      @oauth.get('/api/users.identity?token=' + session[:access_token]).body
    )
    # TODO: for more details:
    # profile = JSON.parse(
    #   @oauth.get('/api/users.profile.get?token='+session[:access_token]).body
    # )
    @user = {
      id: identity['user']['id'],
      name: identity['user']['name']
    }
  end
end

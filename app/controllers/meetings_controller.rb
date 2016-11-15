# Join a meeting
class MeetingsController < ApplicationController
  before_action :authorized_or_leave!
  before_action :oauth_client
  before_action :optain_user

  def show
    # Add user to conference room and redirect to communication GUI
    channel = {
      id:   params.require(:id)
    }
    room = Room.new(channel: channel, user: @user)

    if room.error.present?
      render json: { error: room.error }, status: :bad_request
    else
      redirect_to room.url
    end
  end

  private

  def authorized_or_leave!
    return if params[:access_token].present?
    redirect_to_login
  end

  def redirect_to_login
    redirect_to login_path(redirect_uri: meeting_path(id: params[:id]))
  end

  def optain_user
    # Optain profile from slack
    token = OAuth2::AccessToken.from_kvform(@oauth, '')
    identity = JSON.parse(
      token.get('/api/users.identity?token=' + params[:access_token]).body
    )
    redirect_to_login && return unless identity['user'].present?
    # TODO: for more details:
    # profile = JSON.parse(
    #   @oauth.get('/api/users.profile.get?token='+params[:access_token]).body
    # )
    @user = {
      id: identity['user']['id'],
      name: identity['user']['name']
    }
  end
end

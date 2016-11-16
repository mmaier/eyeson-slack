# Join a meeting
class MeetingsController < ApplicationController
  before_action :authorized_or_leave!
  before_action :oauth_client
  before_action :oauth_access
  before_action :oauth_user

  def show
    # Add user to conference room and redirect to communication GUI
    @channel = {
      id:   params.require(:id),
      name: 'eyeson slack'
    }
    room = Room.new(channel: @channel, user: @user)

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

  def oauth_access
    @oauth_access = OAuth2::AccessToken.from_kvform(@oauth, '')
  end

  def oauth_user
    # fetch user details from slack api
    identity = JSON.parse(
      @oauth_access.get(
        '/api/users.identity?token=' + params.require(:access_token)
      ).body
    )

    redirect_to_login && return unless identity['user'].present?

    @user = {
      id:     identity['user']['id'],
      name:   identity['user']['name'],
      avatar: identity['user']['image_48']
    }
  end
end

# Join a meeting
class MeetingsController < ApplicationController
  before_action :authorized_or_leave!
  before_action :oauth_client
  before_action :oauth_access
  before_action :oauth_user
  before_action :oauth_profile
  before_action :oauth_channel

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
      name:   identity['user']['name']
    }
  end

  def oauth_profile
    profile = JSON.parse(
      @oauth_access.get(
        '/api/users.profile.get?token=' + params.require(:access_token)
      ).body
    )

    @user.merge!(
      avatar: profile['profile']['image_48']
    ) if profile['profile'].present?
  end

  def oauth_channel
    # fetch channel details from slack api
    channel = JSON.parse(
      @oauth_access.get(
        '/api/channels.info?channel=' + params.require(:id) +
        '&token=' + params.require(:access_token)
      ).body
    )

    @channel = {
      id:   params.require(:id),
      name: channel['channel']['name']
    }
  end
end

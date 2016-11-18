# Authenticat users via oauth
class UsersController < ApplicationController
  before_action :handle_oauth_error, only: [:oauth]
  before_action :oauth_client
  before_action :oauth_access, only: [:oauth]
  before_action :oauth_user, only: [:oauth]
  before_action :init_team, only: [:oauth]
  before_action :init_user, only: [:oauth]

  def login
    url = @oauth.auth_code.authorize_url(
      redirect_uri: oauth_url(redirect_uri: params.require(:redirect_uri)),
      scope: 'identity.basic identity.avatar',
      team: team_known?
    )
    redirect_to url
  end

  def oauth
    uri = params.require(:redirect_uri)
    connector = (uri.include?('?') ? '&' : '?')
    redirect_to uri + connector + "user_id=#{@user.id}"
  end

  private

  def handle_oauth_error
    return unless params[:error].present?
    redirect_to login_path(
      redirect_uri: params.require(:redirect_uri)
    )
  end

  def oauth_access
    @oauth_access = @oauth.auth_code.get_token(
      params[:code],
      redirect_uri: oauth_url(redirect_uri: params.require(:redirect_uri))
    )
  end

  def oauth_user
    # fetch user details from slack api
    @identity = JSON.parse(
      @oauth_access.get(
        '/api/users.identity?token=' + @oauth_access.token
      ).body
    )

    return if @identity['user'].present?
    redirect_to login_path(
      redirect_uri: params.require(:redirect_uri)
    )
  end

  def team_known?
    path = begin
      Rails.application.routes.recognize_path(params.require(:redirect_uri))
    rescue
      nil
    end

    return nil unless path.present?
    return path[:id] if path[:controller] == 'meetings' && path[:id].present?
    nil
  end

  def init_team
    @team = Team.find_or_initialize_by(external_id: @identity['team']['id'])
    @team.save!
  end

  def init_user
    @user = User.find_or_initialize_by(
      team_id: @team.id,
      external_id: @identity['user']['id']
    )
    @user.name = @identity['user']['name']
    @user.avatar = @identity['user']['image_48']
    @user.save!
  end
end

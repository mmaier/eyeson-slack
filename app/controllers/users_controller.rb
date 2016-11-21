# Authenticat users via oauth
class UsersController < ApplicationController
  before_action :handle_oauth_error, only: [:oauth]
  before_action :oauth_client
  before_action :oauth_access, only: [:oauth]
  before_action :oauth_user, only: [:oauth]
  before_action :team_and_user, only: [:oauth]

  def setup
    url = @oauth.auth_code.authorize_url(
      redirect_uri: oauth_url,
      scope: 'commands'
    )
    redirect_to url
  end

  def setup_webhook
    return unless params.require(:type) == 'team_changed'
    team = Team.find_by(api_key: params.require(:api_key))
    team.confirmed = true if [true, 'true'].include?(params[:team][:confirmed])
    team.save!
  end

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
      redirect_uri: oauth_url(redirect_uri: params[:redirect_uri])
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
      redirect_uri: params[:redirect_uri]
    )
  end

  def team_known?
    path = begin
      Rails.application.routes.recognize_path(params.require(:redirect_uri))
    rescue
      nil
    end

    return nil unless path.present?
    if path[:controller] == 'meetings' && path[:id].present?
      return Channel.find_by(external_id: path[:id]).team.external_id
    end
    nil
  end

  def team_and_user
    @team = Team.find_by(external_id: @identity['team']['id'])
    redirect_to_setup && return if !@team.present? || !@team.confirmed?
    @user = @team.add!(@identity['user'])
  end

  def redirect_to_setup
    if @team.present?
      redirect_to @team.confirm_url
    else
      team = Team.setup!(
        name: 'Slack Service Application',
        identity: @identity,
        webhooks_url: webhooks_url
      )
      redirect_to team
    end
  end
end

# Authenticat users via oauth
class UsersController < ApplicationController
  before_action :slack_api

  before_action :authorized!, only: [:oauth]
  before_action :valid_user!, only: [:oauth]
  before_action :valid_team_user_relation!, only: [:oauth]

  def login
    redirect_to @slack_api.authorize!(
      redirect_uri: oauth_url(redirect_uri: params.require(:redirect_uri)),
      scope:        'identity.basic identity.avatar',
      team:         team_id_by_url
    )
  end

  def oauth
    uri = params.require(:redirect_uri)
    connector = (uri.include?('?') ? '&' : '?')
    redirect_to uri + connector + "user_id=#{@user.id}"
  end

  private

  def authorized!
    auth = @slack_api.authorized?(
      params,
      oauth_url(redirect_uri: params[:redirect_uri])
    )
    return if auth
    # TODO: redirect to error/help page
    redirect_to login_path(
      redirect_uri: params.require(:redirect_uri)
    )
  end

  def valid_user!
    @identity = @slack_api.get('/users.identity')
    return if @identity['user'].present?
    redirect_to login_path(
      redirect_uri: params[:redirect_uri]
    )
  end

  def valid_team_user_relation!
    @team = Team.find_by(external_id: @identity['team']['id'])
    setup_app! && return if !@team.present? || !@team.ready?
    @user = @team.add!(@identity['user'])
  end

  def setup_app!
    if @team.present?
      redirect_to @team.setup_url
    else
      team = Team.setup!(
        name: 'Slack Service Application',
        identity: @identity,
        webhooks_url: webhooks_url
      )
      redirect_to team
    end
  end

  def team_id_by_url
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
end

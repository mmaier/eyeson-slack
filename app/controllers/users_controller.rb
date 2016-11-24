# Authenticat users via oauth
class UsersController < ApplicationController
  rescue_from SlackApi::NotAuthorized, with: :slack_not_authorized

  before_action :slack_api
  before_action :authorized!, only: [:oauth]
  before_action :user_belongs_to_team!, only: [:oauth]

  def login
    redirect_to @slack_api.authorize!(
      redirect_uri: oauth_url(redirect_uri: params.require(:redirect_uri)),
      scope:        'identity.basic identity.avatar'
    )
  end

  def oauth
    uri = params.require(:redirect_uri)
    connector = (uri.include?('?') ? '&' : '?')
    redirect_to uri + connector + "user_id=#{@user.id}"
  end

  private

  def slack_not_authorized
    redirect_to login_path(
      redirect_uri: params.require(:redirect_uri)
    )
  end

  def authorized!
    @slack_api.authorized?(
      params,
      oauth_url(redirect_uri: params.require(:redirect_uri))
    )
    @identity = @slack_api.get('/users.identity')
  end

  def user_belongs_to_team!
    @team = Team.find_by(external_id: @identity['team']['id'])
    redirect_to(:setup) && return if !@team.present? || !@team.ready?
    @user = @team.add!(@identity['user'])
    @user.access_token = @slack_api.access_token
    @user.save
  end
end

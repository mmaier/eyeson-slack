# Authenticat users via oauth
class UsersController < ApplicationController
  rescue_from SlackApi::NotAuthorized, with: :slack_not_authorized

  before_action :slack_api
  before_action :authorized!, only: [:oauth]
  before_action :user_belongs_to_team!, only: [:oauth]

  def login
    redirect_to @slack_api.authorize!(
      redirect_uri: oauth_url(redirect_uri: params.require(:redirect_uri)),
      scope:        'identity.basic identity.avatar',
      team:         team_id_from_url
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
    @identity = @slack_api.request('/users.identity')
  end

  def user_belongs_to_team!
    @team = Team.find_by(external_id: @identity['team']['id'])
    redirect_to(:setup) && return if !@team.present? || !@team.ready?
    @user = @team.add!(@identity['user'])
  end

  def team_id_from_url
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

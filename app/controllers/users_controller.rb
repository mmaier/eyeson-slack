# Authenticat users via oauth
class UsersController < ApplicationController
  rescue_from SlackApi::NotAuthorized, with: :slack_not_authorized
  rescue_from OAuth2::Error, with: :slack_not_authorized

  before_action :slack_api
  before_action :authorized!, only: [:oauth]
  before_action :user_belongs_to_team!, only: [:oauth]

  def login
    scope = if params[:scope].present?
              params[:scope].split(',')
            else
              %w(identity.basic identity.email identity.avatar)
            end

    redirect_to @slack_api.authorize!(
      redirect_uri: oauth_url(redirect_uri: params.require(:redirect_uri)),
      scope:        scope,
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
  end

  def user_belongs_to_team!
    team_id = @slack_api.params['team']['id']
    @team = Team.find_by(external_id: team_id)
    redirect_to(setup_path(team_id: team_id)) && return unless @team.present?
    @user = @team.add!(access_token: @slack_api.access_token,
                       scope:        @slack_api.params['scope'],
                       identity:     @slack_api.params)
  end

  def team_id_from_url
    path = begin
      Rails.application.routes.recognize_path(params.require(:redirect_uri))
    rescue
      nil
    end

    return nil if path.nil? || path[:id].nil? || path[:controller] != 'meetings'
    Channel.find_by(external_id: path[:id]).try(:team).try(:external_id)
  end
end

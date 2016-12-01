# Authenticat users via oauth
class UsersController < ApplicationController
  rescue_from SlackApi::NotAuthorized, with: :slack_not_authorized

  before_action :slack_api
  before_action :authorized!, only: [:oauth]
  before_action :user_belongs_to_team!, only: [:oauth]

  def login
    redirect_to @slack_api.authorize!(
      redirect_uri: oauth_url(redirect_uri: params.require(:redirect_uri)),
      scope:        'identify users.profile:read chat:write:user',
      team:         team_id_from_url,
      state:        params[:state]
    )
  end

  def oauth
    session[@team.id.to_s] = @user.id.to_s
    session[:state]        = params[:state]
    redirect_to params.require(:redirect_uri)
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
    @identity = @slack_api.request('/auth.test')
    profile   = @slack_api.request('/users.profile.get')
    @identity['email'] = profile['profile']['email']
    @identity.merge!('avatar' => profile['profile']['image_48'])
  end

  def user_belongs_to_team!
    @team = Team.find_by(external_id: @identity['team_id'])
    redirect_to(:setup) && return unless @team.present?
    @user = @team.add!(
      access_token: @slack_api.access_token,
      identity: @identity
    )
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

# handles the team setup process
class TeamsController < ApplicationController
  rescue_from SlackApi::NotAuthorized, with: :slack_not_authorized
  rescue_from OAuth2::Error, with: :slack_not_authorized

  before_action :slack_api
  before_action :logged_in!, only: [:setup]
  before_action :authorized!, only: [:create]

  def setup
    redirect_to @slack_api.authorize!(
      redirect_uri: setup_complete_url,
      scope:        %w[identify commands],
      team:         params[:team_id]
    )
  end

  def create
    @team = Team.setup!(
      external_id: @slack_api.auth['team_id'],
      url:         @slack_api.auth['url'],
      name:        @slack_api.auth['team']
    )
    redirect_to Rails.configuration.services['setup_complete_url']
  end

  private

  def logged_in!
    return if params[:team_id].present? || params[:user_id].present?
    redirect_to login_path(
      redirect_uri: setup_path
    )
  end

  def authorized!
    @slack_api.authorized?(
      params,
      setup_complete_url
    )
  end

  def slack_not_authorized(_e)
    redirect_to :setup
  end
end

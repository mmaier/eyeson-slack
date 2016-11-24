# handles the team setup process
class TeamsController < ApplicationController
  rescue_from SlackApi::NotAuthorized, with: :slack_not_authorized
  rescue_from ApiKey::ValidationFailed, with: :api_key_error

  before_action :slack_api
  before_action :authorized!, only: [:create]

  def setup
    redirect_to @slack_api.authorize!(
      redirect_uri: setup_complete_url,
      scope:        'identify commands'
    )
  end

  def create
    @team = Team.find_by(external_id: @identity['team']['id'])
    redirect_to(@team.setup_url) && return if @team.present?

    team = Team.setup!(
      name: 'Slack Service Application',
      identity: @identity,
      webhooks_url: webhooks_url
    )
    redirect_to team.setup_url
  end

  private

  def authorized!
    @slack_api.authorized?(
      params,
      setup_complete_url
    )
    user = @slack_api.get('/auth.test')
    @identity = @slack_api.identity_from_auth(user)
  end

  def slack_not_authorized
    redirect_to :setup
  end

  def api_key_error(e)
    render json: { error: e }, status: :bad_request
  end
end

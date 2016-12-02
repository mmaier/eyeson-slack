# handles the team setup process
class TeamsController < ApplicationController
  rescue_from SlackApi::NotAuthorized, with: :slack_not_authorized
  rescue_from ApiKey::ValidationFailed, with: :api_key_error

  before_action :slack_api
  before_action :authorized!, only: [:create]

  def setup
    redirect_to @slack_api.authorize!(
      redirect_uri: setup_complete_url,
      scope:        'identify commands chat:write:bot'
    )
  end

  def create
    @team = Team.setup!(
      access_token: @slack_api.access_token,
      identity: @identity
    )

    @slack_api.request('/chat.postMessage',
                       channel: "@#{@identity['user']}",
                       as_user: false,
                       text:    CGI.escape(I18n.t('.setup_complete',
                                                  scope: [:teams, :create])))

    redirect_to @identity['url']
  end

  private

  def authorized!
    @slack_api.authorized?(
      params,
      setup_complete_url
    )
    @identity = @slack_api.request('/auth.test')
  end

  def slack_not_authorized
    redirect_to :setup
  end

  def api_key_error(e)
    render json: { error: e }, status: :bad_request
  end
end

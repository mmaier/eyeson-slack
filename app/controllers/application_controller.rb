# Application Controller
class ApplicationController < ActionController::API
  private

  def oauth_client
    @oauth = OAuth2::Client.new(
      Rails.configuration.services['slack_key'],
      Rails.configuration.services['slack_secret'],
      site: 'https://slack.com',
      authorize_url: '/oauth/authorize',
      token_url: '/api/oauth.access'
    )
  end
end

# Application Controller
class ApplicationController < ActionController::API
  private

  def oauth_client
    @client = OAuth2::Client.new(
      APP_CONFIG['slack_key'],
      APP_CONFIG['slack_secret'],
      site: 'https://slack.com',
      authorize_url: '/oauth/authorize',
      token_url: '/api/oauth.access'
    )
  end
end

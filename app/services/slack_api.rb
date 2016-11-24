# Provides Slack API methods
class SlackApi
  
  class NotAuthorized < StandardError
  end

  def initialize
    @config = Rails.configuration.services
    @oauth = OAuth2::Client.new(
      @config['slack_key'],
      @config['slack_secret'],
      site: 'https://slack.com',
      authorize_url: '/oauth/authorize',
      token_url: '/api/oauth.access'
    )
    @oauth_access = nil
  end

  def authorize!(redirect_uri: nil, scope: nil, team: nil)
    @oauth.auth_code.authorize_url(
      redirect_uri: redirect_uri,
      scope:        scope,
      team:         team
    )
  end

  def authorized?(params, redirect_uri)
    raise NotAuthorized.new(params[:error]) if params[:error].present?
    token_from(
      code: params[:code],
      redirect_uri: redirect_uri
    )
  end

  def get(path, params = {})
    response = @oauth_access.get(
      "/api#{path}" + request_params_from(params)
    )
    respond_with(response)
  end

  private

  def token_from(code: nil, redirect_uri: nil)
    @oauth_access = @oauth.auth_code.get_token(
      code,
      redirect_uri: redirect_uri
    )
  end

  def request_params_from(params)
    p = "?token=#{@oauth_access.token}"
    if params.any?
      p << '&'
      p << params.map { |k, v| "#{k}=#{v}" }.join('&')
    end
    p
  end

  def respond_with(response)
    raise NotAuthorized unless response.status[0] != 2
    body = JSON.parse(response.body)
    raise NotAuthorized.new(body['error']) if body['ok'] != true
    body
  end
end

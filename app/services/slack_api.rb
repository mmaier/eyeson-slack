# Provides Slack API methods
class SlackApi
  class NotAuthorized < StandardError
  end
  class RequestFailed < StandardError
  end
  class MissingScope < StandardError
  end

  include SlackFile
  include SlackMessage

  attr_reader :access_token, :scope

  def initialize(access_token = nil)
    @config       = Rails.application.secrets
    @oauth        = oauth_client
    @access_token = access_token
    @scope        = nil
  end

  def authorize!(redirect_uri: nil, scope: nil, team: nil)
    @oauth.auth_code.authorize_url(
      redirect_uri: redirect_uri,
      scope:        scope.join(','),
      team:         team
    )
  end

  def authorized?(params, redirect_uri)
    raise NotAuthorized, params[:error] if params[:error].present?
    token_from(
      code: params[:code],
      redirect_uri: redirect_uri
    )
  end

  def get(path, params = {})
    request(:get, path, params)
  end

  def post(path, params = {})
    request(:post, path, params)
  end

  private

  def oauth_client
    OAuth2::Client.new(
      @config.slack_key,
      @config.slack_secret,
      site: 'https://slack.com',
      authorize_url: '/oauth/authorize',
      token_url: '/api/oauth.access'
    )
  end

  def token_from(code: nil, redirect_uri: nil)
    oauth_access = @oauth.auth_code.get_token(
      code,
      redirect_uri: redirect_uri
    )
    @access_token = oauth_access.token
    @scope        = oauth_access.params['scope']
  end

  def request(method, path, params)
    req = RestClient::Request.new(
      method: method,
      url: @oauth.site + '/api' + path,
      payload: { token: @access_token }.merge!(params)
    )
    response_for(req)
  end

  def respond_with(req)
    res = begin
      req.execute
    rescue RestClient::ExceptionWithResponse => e
      e.response
    end
    return {} unless res.body.present?
    body = JSON.parse(res.body)
    raise MissingScope, body['needed'] if body['error'] == 'missing_scope'
    raise RequestFailed, body['error'] unless body['ok'] == true
    body
  end
end

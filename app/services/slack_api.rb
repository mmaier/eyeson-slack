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

  DEFAULT_SCOPE = %w(chat:write:user files:write:user).freeze

  attr_reader :access_token, :scope

  def initialize(access_token = nil)
    @config       = Rails.application.secrets
    @oauth        = oauth_client
    @access_token = access_token
    @scope        = nil
    @auth         = nil
    @identity     = nil
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
    oauth_access = @oauth.auth_code.get_token(
      params[:code],
      redirect_uri: redirect_uri
    )
    @access_token = oauth_access.token
    @scope        = oauth_access.params['scope']
  end

  def get(path, params = {})
    request(:get, path, params)
  end

  def post(path, params = {})
    request(:post, path, params)
  end

  def multipart(path, payload = {})
    request(:post, path, {}, payload)
  end

  def auth
    @auth ||= get('/auth.test')
    @auth
  end

  def identity
    @identity ||= get('/users.identity')
    @identity
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

  def request(method, path, params, payload = nil)
    req = RestClient::Request.new(
      method: method,
      url: @oauth.site + '/api' + path,
      payload: payload,
      headers: {
        params: { token: @access_token }.merge!(params)
      }
    )
    response_for(req)
  end

  def response_for(req)
    res = begin
      req.execute
    rescue RestClient::ExceptionWithResponse => e
      e.response
    end
    return {} if res.body.blank?
    body = JSON.parse(res.body)
    raise MissingScope, body['needed'] if body['error'] == 'missing_scope'
    raise RequestFailed, body['error'] unless body['ok'] == true
    body
  end
end

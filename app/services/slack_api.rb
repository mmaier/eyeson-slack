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

  attr_reader :access_token, :params

  def initialize(access_token = nil)
    @config       = Rails.application.secrets
    @oauth        = oauth_client
    @access_token = access_token
    @params       = {}
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
    @params       = oauth_access.params
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

  def request(method, path, params)
    req = RestClient::Request.new(
      method: method,
      url: @oauth.site + '/api' + path,
      headers: {
        accept: 'application/json',
        content_type: 'application/json',
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
    return {} unless res.body.present?
    body = JSON.parse(res.body)
    raise MissingScope, body['needed'] if body['error'] == 'missing_scope'
    raise RequestFailed, body['error'] unless body['ok'] == true
    body
  end
end

# Provides Slack API methods
class SlackApi
  class NotAuthorized < StandardError
  end
  class RequestFailed < StandardError
  end
  class MissingScope < StandardError
  end

  attr_reader :access_token, :scope

  def initialize(access_token = nil)
    @config       = Rails.configuration.services
    @oauth        = oauth_client
    @oauth_access = nil
    @access_token = access_token
    @scope        = nil

    token_from(access_token: @access_token) if @access_token.present?
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

  def request(path, params = {})
    response = @oauth_access.get(
      "/api#{path}" + url_params_from(params)
    )
    respond_with(response)
  end

  def identity_from_info(info)
    name = info['user']['profile']['real_name']
    name ||= info['user']['name']
    {
      'user' => {
        'id'       => info['user']['id'],
        'name'     => name,
        'image_48' => info['user']['profile']['image_48']
      }
    }
  end

  private

  def oauth_client
    OAuth2::Client.new(
      @config['slack_key'],
      @config['slack_secret'],
      site: 'https://slack.com',
      authorize_url: '/oauth/authorize',
      token_url: '/api/oauth.access'
    )
  end

  def token_from(code: nil, redirect_uri: nil, access_token: nil)
    if access_token.present?
      @oauth_access = OAuth2::AccessToken.new(@oauth, access_token)
    else
      @oauth_access = @oauth.auth_code.get_token(
        code,
        redirect_uri: redirect_uri
      )
      @access_token = @oauth_access.token
      @scope        = @oauth_access.params['scope']
    end
  end

  def url_params_from(params)
    p = "?token=#{@access_token}"
    if params.any?
      p << '&'
      p << params.map { |k, v| "#{k}=#{v}" }.join('&')
    end
    p
  end

  def respond_with(response)
    body = JSON.parse(response.body)
    raise MissingScope, body['needed'] if body['error'] == 'missing_scope'
    raise RequestFailed, body['error'] unless body['ok'] == true
    body
  end
end


module AuthorizationHelpers
  def slack_identity(user_id, team_id)
    response = mock('Slack Identity')
    response.expects(:body).returns(
      {
        user: {
          id: user_id,
          name: 'Tester'
        },
        team: {
          id: team_id
        }
      }.to_json
    ).at_least_once
    response
  end

  def oauth_login_success(redirect_uri: nil, team: nil)
    auth_code = mock('Auth code')
    auth_code.expects(:authorize_url)
             .with(
               redirect_uri: oauth_url(redirect_uri: redirect_uri),
               scope: 'identity.basic identity.avatar',
               team: team
             )
             .returns('/slack_oauth')
    oauth = mock('Oauth')
    oauth.expects(:auth_code).returns(auth_code)
    OAuth2::Client.expects(:new).returns(oauth)
  end

  def oauth_token_success(redirect_uri: nil)
    @oauth_access = mock('Oauth token', token: 'abc')
    auth_code = mock('Auth code')
    auth_code.expects(:get_token)
             .with(
               'abc',
               redirect_uri: oauth_url(redirect_uri: redirect_uri)
             )
             .returns(@oauth_access)
    oauth = mock('Oauth')
    oauth.expects(:auth_code).returns(auth_code)
    OAuth2::Client.expects(:new).returns(oauth)
  end

  def slack_api_authorized
    @slack_api = mock('Slack API')
    SlackApi.expects(:new).returns(@slack_api)
    @slack_api.expects(:authorized?).returns(true)
  end

  def rest_response_with(res)
    req = mock('Eyeson Request')
    req.expects(:use_ssl=).at_least_once
    req.expects(:verify_mode=).at_least_once
    req.expects(:request).returns(res).at_least_once
    Net::HTTP.expects(:new).returns(req).at_least_once
  end
end

RSpec.configure do |config|
  config.include AuthorizationHelpers
end

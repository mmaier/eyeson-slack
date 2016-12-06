require 'rails_helper'

RSpec.describe SlackApi, type: :class do
  let(:slack_api) do
    SlackApi.new
  end

  let(:oauth) do
    slack_api.send(:oauth_client)
  end

  it 'initializes valid oauth client' do
    opts = oauth.options
    expect(oauth.site).to be_present
    expect(oauth.id).to be_present
    expect(oauth.secret).to be_present
    expect(opts[:authorize_url]).to be_present
    expect(opts[:token_url]).to be_present
  end

  it 'initializes with existing access_token' do
    slack_api = SlackApi.new('abc123')
    expect(slack_api.access_token).to eq('abc123')
  end

  it 'returns authroization url' do
    redirect_uri = '/test'
    scope = 'test_scope'
    team = 'my_team'

    auth_url = slack_api.authorize!(
      redirect_uri: redirect_uri,
      scope:        scope,
      team:         team
    )
    params = CGI.parse(URI.parse(auth_url).query)

    expect(params['client_id'][0]).to eq(oauth.id)
    expect(params['redirect_uri'][0]).to eq(redirect_uri)
    expect(params['response_type'][0]).to eq('code')
    expect(params['scope'][0]).to eq(scope)
    expect(params['team'][0]).to eq(team)
  end

  it 'sets access token from code' do
    @oauth_access = mock('Oauth token', token: 'abc123')
    auth_code = mock('Auth code')
    auth_code.expects(:get_token)
             .with(
               'abc',
               redirect_uri: '/'
             )
             .returns(@oauth_access)
    oauth = mock('Oauth')
    oauth.expects(:auth_code).returns(auth_code)
    OAuth2::Client.expects(:new).returns(oauth)

    slack_api.send(:token_from, code: 'abc', redirect_uri: '/')
    expect(slack_api.access_token).to eq('abc123')
  end

  it 'sets token when authorized' do
    slack_api.expects(:token_from).with(code: 'abc', redirect_uri: '/')
    slack_api.authorized?({ code: 'abc' }, '/')
  end

  it 'sends requests to slack api' do
    body = { 'ok' => true }
    response = mock('Oauth Response', error: nil, body: body.to_json)
    oauth_access = mock('Oauth token')
    oauth_access.expects(:get).returns(response)
    OAuth2::AccessToken.expects(:new).returns(oauth_access)

    slack_api.send(:token_from, access_token: 'abc123')
    expect(slack_api.request('/user.identity')).to eq(body)
  end

  it 'appends access_token to url query' do
    url = '?token=abc123&key=value&key2=value2'
    slack_api = SlackApi.new('abc123')
    params = {
      key: 'value',
      key2: 'value2'
    }
    expect(slack_api.send(:url_params_from, params)).to eq(url)
  end

  it 'returns json response from oauth client' do
    body = {
      'ok' => true,
      'key' => 'value'
    }
    response = mock('Slack API', error: nil, body: body.to_json)
    expect(slack_api.send(:respond_with, response)).to eq(body)
  end

  it 'returns identity from auth object' do
    auth = slack_auth
    identity = slack_api.send(:identity_from_auth, auth)
    expect(identity['user']['id']).to eq(auth['user_id'])
    expect(identity['user']['name']).to eq(auth['user'])
  end

  it 'raises NotAuthorized when error param is set' do
    expect { slack_api.authorized?({ error: 'some_error' }, nil) }
      .to raise_error(SlackApi::NotAuthorized)
  end

  it 'raises NotAuthorized when api response error is present' do
    response = mock('Slack API')
    response.expects(:error).returns(true).twice
    expect { slack_api.send(:respond_with, response) }
      .to raise_error(SlackApi::NotAuthorized)
  end

  it 'raises NotAuthorized when api resonse does not contain ok=true' do
    response = mock('Slack API', error: nil, body: {
      'ok' => false
    }.to_json)
    expect { slack_api.send(:respond_with, response) }
      .to raise_error(SlackApi::NotAuthorized)
  end
end

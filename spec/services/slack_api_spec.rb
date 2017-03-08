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
    scope = %w(test_scope)
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
    expect(params['scope'][0]).to eq(scope.join(','))
    expect(params['team'][0]).to eq(team)
  end

  it 'sets access token and scope from code' do
    oauth_access = mock('Oauth token')
    oauth_access.expects(:token).returns('abc123').once
    oauth_access.expects(:params).returns('scope' => 'scope1,scope2').once
    auth_code = mock('Auth code')
    auth_code.expects(:get_token)
             .with(
               'abc',
               redirect_uri: '/'
             )
             .returns(oauth_access)
    oauth = mock('Oauth')
    oauth.expects(:auth_code).returns(auth_code)
    OAuth2::Client.expects(:new).returns(oauth)

    slack_api.send(:token_from, code: 'abc', redirect_uri: '/')
    expect(slack_api.access_token).to eq('abc123')
    expect(slack_api.scope).to eq('scope1,scope2')
  end

  it 'sets token when authorized' do
    slack_api.expects(:token_from).with(code: 'abc', redirect_uri: '/')
    slack_api.authorized?({ code: 'abc' }, '/')
  end

  it 'should provide a get method' do
    slack_api.expects(:request).with(:get, 'test', test: true)
    slack_api.get('test', test: true)
  end

  it 'should provide a post method' do
    slack_api.expects(:request).with(:post, 'test', test: true)
    slack_api.post('test', test: true)
  end

  it 'should send requests to slack api' do
    body = { 'ok' => true }
    response = mock('Oauth Response', body: body.to_json)
    oauth_access = mock('Oauth token')
    oauth_access.expects(:request)
                .with(:get, '/api/user.identity', { params: { token: 'abc123' } })
                .returns(response)
    OAuth2::AccessToken.expects(:new).returns(oauth_access)

    slack_api = SlackApi.new('abc123')
    expect(slack_api.get('/user.identity')).to eq(body)
  end

  it 'returns json response from oauth client' do
    body = {
      'ok' => true,
      'key' => 'value'
    }
    response = mock('Slack API', body: body.to_json)
    expect(slack_api.send(:respond_with, response)).to eq(body)
  end

  it 'raises NotAuthorized when error param is set' do
    expect { slack_api.authorized?({ error: 'some_error' }, nil) }
      .to raise_error(SlackApi::NotAuthorized)
  end

  it 'raises RequestFailed when api response ok!=true' do
    response = mock('Slack API', body: {
      'ok' => false
    }.to_json)
    expect { slack_api.send(:respond_with, response) }
      .to raise_error(SlackApi::RequestFailed)
  end

  it 'raises MissingScope when api resonse returns missing_scope error' do
    response = mock('Slack API', body: {
      'ok' => false, error: 'missing_scope'
    }.to_json)
    expect { slack_api.send(:respond_with, response) }
      .to raise_error(SlackApi::MissingScope)
  end
end

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

  it 'sets access token and params from code' do
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

    slack_api.send(:authorized?, { code: 'abc' }, '/')
    expect(slack_api.access_token).to eq('abc123')
    expect(slack_api.scope).to eq('scope1,scope2')
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
    RestClient::Request.expects(:new).with(
      method: :get,
      url: 'https://slack.com/api/user.identity',
      payload: nil,
      headers: { params: { token: 'abc123' } }
    )

    slack_api = SlackApi.new('abc123')
    slack_api.expects(:response_for)
    slack_api.get('/user.identity')
  end

  it 'should handle multipart requests' do
    file = Tempfile.new('test')
    RestClient::Request.expects(:new).with(
      method: :post,
      url: 'https://slack.com/api/files.upload',
      payload: { file: file },
      headers: { params: { token: 'abc123' } }
    )

    slack_api = SlackApi.new('abc123')
    slack_api.expects(:response_for)
    slack_api.multipart('/files.upload', file: file)
  end

  it 'returns json response from oauth client' do
    body = {
      'ok' => true,
      'key' => 'value'
    }
    expect(slack_api.send(:response_for, slack_api_response_with(body))).to eq(body)
  end

  it 'raises NotAuthorized when error param is set' do
    expect { slack_api.authorized?({ error: 'some_error' }, nil) }
      .to raise_error(SlackApi::NotAuthorized)
  end

  it 'raises RequestFailed when api response ok!=true' do
    body = {
      'ok' => false
    }
    expect { slack_api.send(:response_for, slack_api_response_with(body)) }
      .to raise_error(SlackApi::RequestFailed)
  end

  it 'raises MissingScope when api resonse returns missing_scope error' do
    body = {
      'ok' => false, error: 'missing_scope'
    }
    expect { slack_api.send(:response_for, slack_api_response_with(body)) }
      .to raise_error(SlackApi::MissingScope)
  end

  it 'should return existing auth from authorization' do
    slack_api.instance_variable_set(:@auth, { 'user' => 'value' })
    expect(slack_api.auth).to eq({ 'user' => 'value' })
  end

  it 'should fetch auth' do
    slack_api.expects(:get).with('/auth.test').returns({ 'user' => 'value' })
    expect(slack_api.auth).to eq({ 'user' => 'value' })
  end

  it 'should return existing identity from authorization' do
    slack_api.instance_variable_set(:@identity, { 'user' => { 'name' => 'value' } })
    expect(slack_api.identity).to eq({ 'user' => { 'name' => 'value' } })
  end

  it 'should fetch identity' do
    slack_api.expects(:get).with('/users.identity').returns({ 'user' => { 'name' => 'value' } })
    expect(slack_api.identity).to eq({ 'user' => { 'name' => 'value' } })
  end
end

def slack_api_response_with(body)
  res = mock('Response')
  res.expects(:body).returns(body.to_json).twice
  mock('Rest Client', execute: res)
end

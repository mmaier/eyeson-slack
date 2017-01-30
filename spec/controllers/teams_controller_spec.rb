require 'rails_helper'

RSpec.describe TeamsController, type: :controller do
  it { should rescue_from(SlackApi::NotAuthorized).with(:slack_not_authorized) }
  it { should rescue_from(ApiKey::ValidationFailed).with(:api_key_error) }

  it 'should redirect_to login unless team_id is set' do
    get :setup
    expect(response).to redirect_to(login_path(redirect_uri: setup_path))
  end

  it 'should ask for command permissions during setup' do
    expects_authorize_with(
      redirect_uri: setup_complete_url,
      scope: %w(identify commands chat:write:user),
      team: 'xyz'
    )
    get :setup, params: { team_id: 'xyz' }
    expect(response.status).to redirect_to('https://slack/auth_url')
  end

  it 'should set up api key and redirect to slack' do
    slack_api_authorized
    auth = slack_auth
    @slack_api.expects(:request).with('/auth.test').returns(auth)
    @slack_api.expects(:request)
              .with('/users.identity')
              .returns(slack_identity(user_id: auth['user_id']))
    res = mock('Eyeson result', body: {
      api_key: Faker::Crypto.md5
    }.to_json)
    uses_internal_api
    api_response_with(res)

    get :create
    expect(response).to redirect_to(Rails.configuration.services['setup_complete_url'])
  end

  it 'should use team name, user email, url and external id for setup' do
    slack_api_authorized
    auth = slack_auth
    identity = slack_identity(user_id: auth['user_id'])
    @slack_api.expects(:request).with('/auth.test').returns(auth)
    @slack_api.expects(:request)
              .with('/users.identity')
              .returns(identity)
    team = mock('eyeson Team')
    Team.expects(:setup!).with(external_id: auth['team_id'],
                               url:         auth['url'],
                               name:        auth['team'],
                               email:       identity['user']['email'])
        .returns(team)
    get :create
    expect(response).to redirect_to(Rails.configuration.services['setup_complete_url'])
  end

  it 'should redirect to setup when error is raised' do
    slack_api_authorized
    @slack_api.expects(:request)
              .raises(SlackApi::NotAuthorized)
    get :create
    expect(response).to redirect_to(setup_path)
  end

  it 'should handle eyeson api error' do
    slack_api_authorized
    @slack_api.expects(:request).with('/auth.test').returns(slack_auth)
    @slack_api.expects(:request)
              .with('/users.identity')
              .returns(slack_identity)

    ApiKey.expects(:new)
          .raises(ApiKey::ValidationFailed)
    get :create
    expect(response.status).to eq(400)
  end
end

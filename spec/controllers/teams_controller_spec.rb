require 'rails_helper'

RSpec.describe TeamsController, type: :controller do
  it { should rescue_from(SlackApi::NotAuthorized).with(:slack_not_authorized) }
  it { should rescue_from(ApiKey::ValidationFailed).with(:api_key_error) }

  it 'should ask for command permissions during setup' do
    expects_authorize_with(
      redirect_uri: setup_complete_url,
      scope:        'identify commands'
    )
    get :setup
    expect(response.status).to redirect_to('https://slack/auth_url')
  end

  it 'should setup team and redirect to api console' do
    slack_api_authorized
    user = slack_auth_test
    @slack_api.expects(:get).returns(user)
    @slack_api.expects(:identity_from_auth)
              .with(user)
              .returns(slack_identity(
                         user_id: user['user_id'],
                         team_id: user['team_id']
              ))

    res = mock('Eyeson result', body: {
      api_key: Faker::Crypto.md5,
      links: {
        setup: 'https://test.api/setup_url'
      }
    }.to_json)
    rest_response_with(res)

    get :create
    expect(response).to redirect_to('https://test.api/setup_url')
  end

  it 'should redirect to setup when error is raised' do
    slack_api_authorized
    @slack_api.expects(:get)
              .raises(SlackApi::NotAuthorized)
    get :create
    expect(response).to redirect_to(setup_path)
  end

  it 'should handle eyeson api error' do
    slack_api_authorized
    user = slack_auth_test
    @slack_api.expects(:get).returns(user)
    @slack_api.expects(:identity_from_auth)
              .with(user)
              .returns(slack_identity(
                         user_id: user['user_id'],
                         team_id: user['team_id']
              ))

    ApiKey.expects(:new)
          .raises(ApiKey::ValidationFailed)
    get :create
    expect(response.status).to eq(400)
  end
end

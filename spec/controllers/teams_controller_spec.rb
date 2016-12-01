require 'rails_helper'

RSpec.describe TeamsController, type: :controller do
  it { should rescue_from(SlackApi::NotAuthorized).with(:slack_not_authorized) }
  it { should rescue_from(ApiKey::ValidationFailed).with(:api_key_error) }

  it 'should ask for command permissions during setup' do
    expects_authorize_with(
      redirect_uri: setup_complete_url,
      scope:        'identify commands chat:write:bot'
    )
    get :setup
    expect(response.status).to redirect_to('https://slack/auth_url')
  end

  it 'should setup team and redirect to api console' do
    slack_api_authorized
    @slack_api.expects(:request).returns(slack_identity)
    @slack_api.expects(:access_token).returns('abc123')

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

  it 'should update access token for existing team' do
    slack_api_authorized
    team = create(:team)
    identity = slack_identity(team_id: team.external_id)
    @slack_api.expects(:request).returns(identity)
    @slack_api.expects(:access_token).returns('abc123')
    get :create
    team.reload
    expect(team.access_token).to eq('abc123')
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
    @slack_api.expects(:request).returns(slack_identity)
    @slack_api.expects(:access_token).returns('abc123')

    ApiKey.expects(:new)
          .raises(ApiKey::ValidationFailed)
    get :create
    expect(response.status).to eq(400)
  end
end

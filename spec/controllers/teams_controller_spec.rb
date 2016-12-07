require 'rails_helper'

RSpec.describe TeamsController, type: :controller do
  it { should rescue_from(SlackApi::NotAuthorized).with(:slack_not_authorized) }
  it { should rescue_from(ApiKey::ValidationFailed).with(:api_key_error) }

  it 'should ask for command permissions during setup' do
    expects_authorize_with(
      redirect_uri: setup_complete_url,
      scope:        'identify commands chat:write:user chat:write:bot'
    )
    get :setup
    expect(response.status).to redirect_to('https://slack/auth_url')
  end

  it 'should setup team and redirect to slack' do
    slack_api_authorized
    identity = slack_auth
    @slack_api.expects(:request).with('/auth.test').returns(identity)
    @slack_api.expects(:identity_from_auth)
              .with(identity)
              .returns(slack_identity(user_id: identity['user_id']))
    @slack_api.expects(:access_token).returns('abc123')
    @slack_api.expects(:request).with('/chat.postMessage',
                                      channel: "@#{identity['user']}",
                                      as_user: false,
                                      text:    CGI.escape(
                                        I18n.t('.setup_complete',
                                               scope: [:teams, :create])
                                      ))

    res = mock('Eyeson result', body: {
      api_key: Faker::Crypto.md5
    }.to_json)
    uses_internal_api
    api_response_with(res)

    get :create
    expect(response).to redirect_to('https://eyeson-test.slack.com')
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
    @slack_api.expects(:request).returns(slack_auth)

    ApiKey.expects(:new)
          .raises(ApiKey::ValidationFailed)
    get :create
    expect(response.status).to eq(400)
  end
end

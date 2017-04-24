require 'rails_helper'

RSpec.describe TeamsController, type: :controller do
  it { should rescue_from(SlackApi::NotAuthorized).with(:slack_not_authorized) }
  it { should rescue_from(OAuth2::Error).with(:slack_not_authorized) }

  it 'should redirect_to login unless team_id is set' do
    get :setup
    expect(response).to redirect_to(login_path(redirect_uri: setup_path))
  end

  it 'should ask for command permissions during setup' do
    expects_authorize_with(
      redirect_uri: setup_complete_url,
      scope: %w(identify commands chat:write:user files:write:user),
      team: 'xyz'
    )
    get :setup, params: { team_id: 'xyz' }
    expect(response.status).to redirect_to('https://slack/auth_url')
  end

  it 'should use team name, url and external id for setup' do
    expects_slack_api_authorized
    auth = slack_auth
    @slack_api.expects(:auth).returns(auth).at_least_once
    team = mock('eyeson Team')
    Team.expects(:setup!).with(external_id: auth['team_id'],
                               url:         auth['url'],
                               name:        auth['team'])
        .returns(team)
    get :create
    expect(response).to redirect_to(
      Rails.configuration.services['setup_complete_url']
    )
  end

  it 'should redirect to setup when error is raised' do
    expects_slack_api_authorized
    @slack_api.expects(:auth)
              .raises(SlackApi::NotAuthorized)
    get :create
    expect(response).to redirect_to(setup_path)
  end
end

require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  it 'should setup team and redirect to api console' do
    slack_api_authorized
    @slack_api.expects(:get).returns(slack_identity)

    res = mock('Eyeson result', body: {
      api_key: Faker::Crypto.md5,
      links: {
        setup: 'https://test.api/setup_url'
      }
    }.to_json)
    rest_response_with(res)

    get :oauth, params: { redirect_uri: setup_complete_path }
    expect(response).to redirect_to('https://test.api/setup_url')
  end

  it 'should redirect to setup_url on setup for existing team' do
    team = create(:team, ready: false, setup_url: 'https://some_url')
    slack_api_authorized
    @slack_api.expects(:get).returns(slack_identity(team_id: team.external_id))

    get :oauth, params: { redirect_uri: setup_complete_path }
    expect(response).to redirect_to('https://some_url')
  end

  it 'should invoke oauth and redirect to slack login' do
    expects_authorize_with(
      redirect_uri: oauth_url(redirect_uri: '/redir'),
      scope:        'identity.basic identity.avatar',
      team:         nil
    )

    get :login, params: { redirect_uri: '/redir' }
    expect(response).to redirect_to('https://slack/auth_url')
  end

  it 'should authorize with team id on meetings#show' do
    channel = create(:channel)
    redirect_uri = meeting_path(id: channel.external_id)

    expects_authorize_with(
      redirect_uri: oauth_url(redirect_uri: redirect_uri),
      scope:        'identity.basic identity.avatar',
      team:         channel.team.external_id
    )

    get :login, params: { redirect_uri: redirect_uri }
    expect(response).to redirect_to('https://slack/auth_url')
  end

  it 'should redirect to redirect_uri on oauth error' do
    redirect_uri = meeting_path(id: '123')
    get :oauth, params: { error: 'some_error', redirect_uri: redirect_uri }
    expect(response).to redirect_to(login_path(redirect_uri: redirect_uri))
  end

  it 'should redirect after oauth success' do
    team = create(:team)
    user = create(:user, team: team)
    redirect_uri = meeting_path(id: '123')

    slack_api_authorized
    @slack_api.expects(:get)
              .returns(slack_identity(
                         user_id: user.external_id,
                         team_id: team.external_id
              ))

    get :oauth, params: { redirect_uri: redirect_uri }
    expect(response).to redirect_to(redirect_uri + "?user_id=#{user.id}")
  end

  it 'should handle slack api error' do
    redirect_uri = meeting_path(id: '123')

    @slack_api = mock('Slack API')
    SlackApi.expects(:new).returns(@slack_api)
    @slack_api.expects(:authorized?).returns(false)

    get :oauth, params: { redirect_uri: redirect_uri }
    expect(response).to redirect_to(login_path(redirect_uri: redirect_uri))
  end

  it 'should handle invalid user' do
    redirect_uri = meeting_path(id: '123')

    slack_api_authorized
    @slack_api.expects(:get)
              .returns(error: 'some_error')

    get :oauth, params: { redirect_uri: redirect_uri }
    expect(response).to redirect_to(login_path(redirect_uri: redirect_uri))
  end
end

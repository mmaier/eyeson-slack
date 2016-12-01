require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  it { should rescue_from(SlackApi::NotAuthorized).with(:slack_not_authorized) }

  it 'should invoke oauth and redirect to slack login' do
    expects_authorize_with(
      redirect_uri: oauth_url(redirect_uri: '/redir'),
      scope:        'identify users.profile:read chat:write:user',
      team:         nil,
      state:        nil
    )

    get :login, params: { redirect_uri: '/redir' }
    expect(response).to redirect_to('https://slack/auth_url')
  end

  it 'should redirect back to login on oauth error' do
    redirect_uri = meeting_path(id: '123')
    get :oauth, params: { error: 'some_error', redirect_uri: redirect_uri }
    expect(response).to redirect_to(login_path(redirect_uri: redirect_uri))
  end

  it 'should redirect after oauth success' do
    team = create(:team)
    user = create(:user, team: team)
    redirect_uri = meeting_path(id: '123')

    slack_api_authorized
    @slack_api.expects(:request)
              .with('/auth.test')
              .returns(slack_identity(
                         user_id: user.external_id,
                         team_id: team.external_id
              ))
    @slack_api.expects(:request)
              .with('/users.profile.get')
              .returns(slack_profile)

    @slack_api.expects(:access_token).returns(user.access_token)

    get :oauth, params: { redirect_uri: redirect_uri }
    user.reload
    expect(response).to redirect_to(redirect_uri)
  end

  it 'should authorize with team id on meetings#show' do
    channel = create(:channel)
    redirect_uri = meeting_path(id: channel.external_id)

    expects_authorize_with(
      redirect_uri: oauth_url(redirect_uri: redirect_uri),
      scope:        'identify users.profile:read chat:write:user',
      team:         channel.team.external_id,
      state:        nil
    )

    get :login, params: { redirect_uri: redirect_uri }
    expect(response).to redirect_to('https://slack/auth_url')
  end

  it 'should handle slack api error' do
    redirect_uri = meeting_path(id: '123')
    get :oauth, params: { error: 'some_error', redirect_uri: redirect_uri }
    expect(response).to redirect_to(login_path(redirect_uri: redirect_uri))
  end

  it 'should handle invalid user' do
    redirect_uri = meeting_path(id: '123')

    slack_api_authorized
    @slack_api.expects(:request)
              .raises(SlackApi::NotAuthorized)

    get :oauth, params: { redirect_uri: redirect_uri }
    expect(response).to redirect_to(login_path(redirect_uri: redirect_uri))
  end
end

require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  it 'should invoke oauth and redirect to slack login' do
    redirect_uri = '/'
    oauth_login_success(redirect_uri: redirect_uri, team: nil)
    get :login, params: { redirect_uri: redirect_uri }
    expect(response).to redirect_to('/slack_oauth')
  end

  it 'should authorize with team id on meetings#show' do
    redirect_uri = meeting_path(id: '123')
    oauth_login_success(redirect_uri: redirect_uri, team: '123')
    get :login, params: { redirect_uri: redirect_uri }
    expect(response).to redirect_to('/slack_oauth')
  end

  it 'should redirect to redirect_uri on oauth error' do
    redirect_uri = meeting_path(id: '123')
    get :oauth, params: { error: 'some_error', redirect_uri: redirect_uri }
    expect(response).to redirect_to(login_path(redirect_uri: redirect_uri))
  end

  it 'should redirect after oauth success' do
    team = Team.where(external_id: 'abc').first_or_create!
    user = User.where(external_id: '123', team: team).first_or_create!
    redirect_uri = meeting_path(id: '123')

    oauth_access_success(redirect_uri: redirect_uri)
    @oauth_access.expects(:get).returns(slack_identity)

    get :oauth, params: { code: 'abc', redirect_uri: redirect_uri }
    expect(response).to redirect_to(redirect_uri + "?user_id=#{user.id}")
  end

  it 'should handle slack api error' do
    redirect_uri = meeting_path(id: '123')

    error = mock('Slack error', body: { error: 'blabla' }.to_json)
    oauth_access_success(redirect_uri: redirect_uri)
    @oauth_access.expects(:get).returns(error)

    get :oauth, params: { code: 'abc', redirect_uri: redirect_uri }
    expect(response).to redirect_to(login_path(redirect_uri: redirect_uri))
  end
end

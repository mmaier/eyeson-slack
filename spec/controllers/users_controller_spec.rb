require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  it 'should setup team and redirect to setup' do
    slack_api_authorized
    new_identity = {
      'user' => {
        'id' => '123',
        'name' => 'Tester'
      },
      'team' => {
        'id' => Faker::Code.isbn
      }
    }
    @slack_api.expects(:get).returns(new_identity)

    res = mock('Eyeson result', body: {
      api_key: Faker::Crypto.md5,
      links: {
        setup: 'https://test.api/setup_url'
      }
    }.to_json)
    rest_response_with(res)

    get :oauth
    expect(response).to redirect_to('https://test.api/setup_url')
  end

  it 'should redirect to setup_url on setup for existing team' do
    team = create(:team, ready: false, setup_url: 'https://some_url')
    slack_api_authorized
    new_identity = {
      'user' => {
        'id' => '123',
        'name' => 'Tester'
      },
      'team' => {
        'id' => team.external_id
      }
    }
    @slack_api.expects(:get).returns(new_identity)

    get :oauth
    expect(response).to redirect_to('https://some_url')
  end

  it 'should invoke oauth and redirect to slack login' do
    redirect_uri = '/'
    oauth_login_success(redirect_uri: redirect_uri, team: nil)
    get :login, params: { redirect_uri: redirect_uri }
    expect(response).to redirect_to('/slack_oauth')
  end

  it 'should authorize with team id on meetings#show' do
    channel = create(:channel)
    redirect_uri = meeting_path(id: channel.external_id)
    oauth_login_success(
      redirect_uri: redirect_uri,
      team: channel.team.external_id
    )
    get :login, params: { redirect_uri: redirect_uri }
    expect(response).to redirect_to('/slack_oauth')
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

    oauth_token_success(redirect_uri: redirect_uri)
    @oauth_access.expects(:get).returns(
      slack_identity(user.external_id, team.external_id)
    )

    get :oauth, params: { code: 'abc', redirect_uri: redirect_uri }
    expect(response).to redirect_to(redirect_uri + "?user_id=#{user.id}")
  end

  it 'should handle slack api error' do
    redirect_uri = meeting_path(id: '123')

    error = mock('Slack error', body: { error: 'blabla' }.to_json)
    oauth_token_success(redirect_uri: redirect_uri)
    @oauth_access.expects(:get).returns(error)

    get :oauth, params: { code: 'abc', redirect_uri: redirect_uri }
    expect(response).to redirect_to(login_path(redirect_uri: redirect_uri))
  end
end

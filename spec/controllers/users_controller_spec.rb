require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  it 'should invoke oauth and redirect to slack login' do
    redirect_uri = meeting_path(id: '123')

    auth_code = mock('Auth code')
    auth_code.expects(:authorize_url)
             .with(
               redirect_uri: oauth_url(redirect_uri: redirect_uri),
               scope: 'identity.basic'
             )
             .returns('/slack_oauth')
    oauth = mock('Oauth')
    oauth.expects(:auth_code).returns(auth_code)
    OAuth2::Client.expects(:new).returns(oauth)

    get :login, params: { redirect_uri: redirect_uri }
    expect(response).to redirect_to('/slack_oauth')
  end

  it 'should redirect after oauth success' do
    redirect_uri = meeting_path(id: '123')

    token = mock('Oauth token', token: 'abc')
    auth_code = mock('Auth code')
    auth_code.expects(:get_token)
             .with(
               'abc',
               redirect_uri: oauth_url(redirect_uri: redirect_uri)
             )
             .returns(token)
    oauth = mock('Oauth')
    oauth.expects(:auth_code).returns(auth_code)
    OAuth2::Client.expects(:new).returns(oauth)

    get :oauth, params: { code: 'abc', redirect_uri: redirect_uri }
    expect(response).to redirect_to(redirect_uri + '?access_token=abc')
  end
end

require 'rails_helper'

RSpec.describe MeetingsController, type: :controller do
  it 'should redirect to login unless access_token present' do
    id = 'xyz'
    get :show, params: { id: id }
    redirect = login_path(redirect_uri: meeting_path(id: id))
    expect(response).to redirect_to(redirect)
  end

  it 'should add user to room and redirect to room url' do
    id = 'xyz'
    gui = 'http://test.host/gui'

    oauth_user_present
    res = mock('Eyeson result', body: { links: { gui: gui } }.to_json)
    rest_response_with(res)

    get :show, params: { id: id, access_token: '123' }
    expect(response.status).to eq(302)
    expect(response).to redirect_to(gui)
  end

  it 'should handle eyeson api error' do
    id = 'xyz'
    error = 'some error'

    oauth_user_present
    res = mock('Eyeson result', body: { error: error }.to_json)
    rest_response_with(res)

    get :show, params: { id: id, access_token: '123' }
    expect(response.status).to eq(400)
    expect(JSON.parse(response.body)['error']).to eq(error)
  end

  it 'should handle slack api error' do
    id = 'xyz'

    error = mock('Slack error', body: { error: 'blabla' }.to_json)
    token = mock('Oauth token', get: error)
    OAuth2::AccessToken.expects(:from_kvform).returns(token)

    get :show, params: { id: id, access_token: '123' }
    redirect = login_path(redirect_uri: meeting_path(id: id))
    expect(response).to redirect_to(redirect)
  end
end

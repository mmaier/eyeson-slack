require 'rails_helper'

RSpec.describe MeetingsController, type: :controller do
  it 'should redirect to login unless session present' do
    id = 'xyz'
    get :show, params: { id: id }
    expect(response).to redirect_to(login_path(redirect_uri: meeting_path(id: id)))
  end

  it 'should add user to room and redirect to room url' do
    id = 'xyz'
    gui = 'http://test.host/gui'

    authorized
    oauth_success

    room = mock('Eyeson room', url: gui, error: nil)
    Room.stubs(:new).returns(room)

    get :show, params: { id: id }
    expect(response.status).to eq(302)
    expect(response.headers['Location']).to eq(gui)
  end

  it 'should handle oauth error' do
    id = 'xyz'

    authorized

    get :show, params: { id: id }
    expect(response.headers['Location']).to redirect_to(login_path(redirect_uri: meeting_path(id: id)))
  end

  it 'should handle eyeson api error' do
    id = 'xyz'
    error = 'some error'

    authorized
    oauth_success

    room = mock('Eyeson room')
    Room.stubs(:new).returns(room)
    room.expects(:error).returns(error).twice

    get :show, params: { id: id }
    expect(response.status).to eq(400)
    expect(JSON.parse(response.body)['error']).to eq(error)
  end
end

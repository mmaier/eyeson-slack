require 'rails_helper'

RSpec.describe MeetingsController, type: :controller do  
  it { should rescue_from(Eyeson::Room::ValidationFailed).with(:room_error) }
  it { should rescue_from(SlackApi::RequestFailed).with(:enter_room) }
  it { should rescue_from(SlackApi::MissingScope).with(:missing_scope) }

  it 'should redirect to login unless user present' do
    id = create(:channel).external_id
    get :show, params: { id: id }
    redirect = login_path(
      redirect_uri: meeting_path(id: id)
    )
    expect(response).to redirect_to(redirect)
  end

  it 'should redirect_to slack unless channel known' do
    user = create(:user)
    get :show, params: { id: Faker::Code.isbn, user_id: user.id }
    expect(response).to redirect_to(user.team.url)
  end

  it 'should redirect to correct slack team unless user belongs to team' do
    team1 = create(:team)
    team2 = create(:team)
    expect(team1).not_to eq(team2)
    channel = create(:channel, team: team1)
    user = create(:user, team: team2)
    get :show, params: { id: channel.external_id, user_id: user.id }
    expect(response).to redirect_to(channel.team.url)
  end

  it 'should add user to room and redirect to room url' do
    channel = create(:channel)
    user = create(:user, team: channel.team)
    gui = 'http://test.host/gui'

    Eyeson::Room.expects(:new).with(id: channel.external_id,
                                    name: channel.name,
                                    user: user)
                              .returns(mock('Room URL', url: gui))

    expects_slack_request_with(user.access_token)
    Eyeson::Internal.expects(:post)

    get :show, params: { id: channel.external_id, user_id: user.id }
    expect(response.status).to eq(302)
    expect(response).to redirect_to(gui)
  end

  it 'should send a chat message after join' do
    channel = create(:channel)
    user = create(:user, team: channel.team)

    expects_eyeson_room_with
    expects_slack_request_with(user.access_token)
    Eyeson::Internal.expects(:post)

    get :show, params: { id: channel.external_id, user_id: user.id }
  end

  it 'should set api key on room create' do
    channel = create(:channel)
    user = create(:user, team: channel.team)
    Eyeson.configuration.expects(:api_key=).with(user.team.api_key)
    
    expects_eyeson_room_with
    expects_slack_request_with(user.access_token)
    Eyeson::Internal.expects(:post)

    get :show, params: { id: channel.external_id, user_id: user.id }
  end

  it 'should handle eyeson api error' do
    channel = create(:channel)
    user = create(:user, team: channel.team)
    error = 'some error'

    Eyeson::Room.expects(:new)
                .raises(Eyeson::Room::ValidationFailed, error)

    get :show, params: { id: channel.external_id, user_id: user.id }
    expect(response.status).to eq(400)
    expect(JSON.parse(response.body)['error']).to eq(error)
  end

  it 'should handle user missing scope error' do
    channel = create(:channel)
    user = create(:user, team: channel.team, scope: ['some_scope'])

    get :show, params: { id: channel.external_id, user_id: user.id }
    redirect = login_path(
      redirect_uri: meeting_path(id: channel.external_id),
      scope: 'chat:write:user'
    )
    expect(response).to redirect_to(redirect)
  end

  it 'should handle slack missing scope error' do
    channel = create(:channel)
    user = create(:user, team: channel.team)
    
    expects_eyeson_room_with

    SlackApi.expects(:new).raises(SlackApi::MissingScope, 'missing_scope')

    get :show, params: { id: channel.external_id, user_id: user.id }
    redirect = login_path(
      redirect_uri: meeting_path(id: channel.external_id),
      scope: 'missing_scope'
    )
    expect(response).to redirect_to(redirect)
  end

  it 'should handle slack request error' do
    channel = create(:channel)
    user = create(:user, team: channel.team)
    gui = 'http://test.host/gui'

    expects_eyeson_room_with(gui)
    SlackApi.expects(:new).raises(SlackApi::RequestFailed)

    get :show, params: { id: channel.external_id, user_id: user.id }
    expect(response).to redirect_to(gui)
  end

  it 'should update intercom with ip address' do
    channel = create(:channel)
    user = create(:user, team: channel.team)
    @request.headers['REMOTE_ADDR'] = '127.0.0.1'
    @request.headers['HTTP_X_FORWARDED_FOR'] = '123.123.123.123, 127.0.0.1'

    expects_eyeson_room_with
    expects_slack_request_with(user.access_token)

    Eyeson::Internal.expects(:post).with('/intercom',
                          email: user.email,
                          ref: 'VIDEOMEETING',
                          fields: {
                            last_seen_ip: '123.123.123.123',
                            videomeetings_slack_info: user.team.name
                          },
                          increment: {
                            videomeetings_slack_count: true
                          })

    get :show, params: { id: channel.external_id, user_id: user.id }
  end
end

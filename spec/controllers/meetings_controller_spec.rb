require 'rails_helper'

RSpec.describe MeetingsController, type: :controller do
  it { should rescue_from(Room::ValidationFailed).with(:room_error) }
  it { should rescue_from(SlackApi::NotAuthorized).with(:slack_not_authorized) }

  it 'should redirect to login unless user present' do
    id = create(:channel).external_id
    get :show, params: { id: id }
    redirect = login_path(redirect_uri: meeting_path(id: id))
    expect(response).to redirect_to(redirect)
  end

  it 'should redirect_to setup unless channel known' do
    authorized_as(create(:user))
    get :show, params: { id: Faker::Code.isbn }
    expect(response).to redirect_to(setup_path)
  end

  it 'should verify that user belongs to channel team' do
    team1 = create(:team)
    team2 = create(:team)
    expect(team1).not_to eq(team2)
    channel = create(:channel, team: team1)
    user = create(:user, team: team2)
    authorized_as(user)

    get :show, params: { id: channel.external_id }
    redirect = login_path(redirect_uri: meeting_path(id: channel.external_id))
    expect(response).to redirect_to(redirect)
  end

  it 'should add user to room and redirect to room url' do
    channel = create(:channel)
    user = create(:user, team: channel.team)
    authorized_as(user)
    gui = 'http://test.host/gui'

    res = mock('Eyeson result', body: { links: { gui: gui } }.to_json)
    rest_response_with(res)

    @slack_api = mock('Slack API')
    SlackApi.expects(:new).with(user.access_token).returns(@slack_api)
    @slack_api.expects(:request).once

    get :show, params: { id: channel.external_id }
    expect(response.status).to eq(302)
    expect(response).to redirect_to(gui)
  end

  it 'should send a chat message after join' do
    channel = create(:channel)
    user = create(:user, team: channel.team)
    authorized_as(user)
    Room.expects(:new).returns(mock('URL', url: '/'))
    slack_api = mock('Slack API')
    slack_api.expects(:request).once
    SlackApi.expects(:new).returns(slack_api)
    get :show, params: { id: channel.external_id }
  end

  it 'should handle eyeson api error' do
    channel = create(:channel)
    user = create(:user, team: channel.team)
    authorized_as(user)
    error = 'some error'

    res = mock('Eyeson result', body: { error: error }.to_json)
    rest_response_with(res)

    get :show, params: { id: channel.external_id }
    expect(response.status).to eq(400)
    expect(JSON.parse(response.body)['error']).to eq(error)
  end

  it 'should handle slack api error' do
    channel = create(:channel)
    user = create(:user, team: channel.team)
    authorized_as(user)
    res = mock('Eyeson result', body: { links: { gui: '' } }.to_json)
    rest_response_with(res)
    SlackApi.expects(:new).raises(SlackApi::NotAuthorized)
    get :show, params: { id: channel.external_id }
    redirect = login_path(redirect_uri: meeting_path(id: channel.external_id))
    expect(response).to redirect_to(redirect)
  end
end

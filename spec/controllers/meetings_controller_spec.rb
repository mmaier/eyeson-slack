require 'rails_helper'

RSpec.describe MeetingsController, type: :controller do
  it { should rescue_from(Room::ValidationFailed).with(:room_error) }

  it 'should redirect to login unless user present' do
    id = create(:channel).external_id
    get :show, params: { id: id }
    redirect = login_path(redirect_uri: meeting_path(id: id))
    expect(response).to redirect_to(redirect)
  end

  it 'should redirect_to setup unless channel known' do
    get :show, params: { id: Faker::Code.isbn, user_id: create(:user).id }
    expect(response).to redirect_to(setup_path)
  end

  it 'should verify that user belongs to channel team' do
    team1 = create(:team)
    team2 = create(:team)
    expect(team1).not_to eq(team2)
    channel = create(:channel, team: team1)
    user = create(:user, team: team2)

    get :show, params: { id: channel.external_id, user_id: user.id }
    redirect = login_path(redirect_uri: meeting_path(id: channel.external_id))
    expect(response).to redirect_to(redirect)
  end

  it 'should revoke access token when user does not belong to team' do
    team1 = create(:team)
    team2 = create(:team)
    expect(team1).not_to eq(team2)
    channel = create(:channel, team: team1)
    user = create(:user, team: team2, access_token: 'abc123')

    slack_api = mock('Slack API')
    SlackApi.expects(:new).with('abc123').returns(slack_api)
    slack_api.expects(:get).with('/auth.revoke')

    get :show, params: { id: channel.external_id, user_id: user.id }
    redirect = login_path(redirect_uri: meeting_path(id: channel.external_id))
    expect(response).to redirect_to(redirect)
  end

  it 'should add user to room and redirect to room url' do
    channel = create(:channel)
    user = create(:user, team: channel.team)
    gui = 'http://test.host/gui'

    res = mock('Eyeson result', body: { links: { gui: gui } }.to_json)
    rest_response_with(res)

    get :show, params: { id: channel.external_id, user_id: user.id }
    expect(response.status).to eq(302)
    expect(response).to redirect_to(gui)
  end

  it 'should handle eyeson api error' do
    channel = create(:channel)
    user = create(:user, team: channel.team)
    error = 'some error'

    res = mock('Eyeson result', body: { error: error }.to_json)
    rest_response_with(res)

    get :show, params: { id: channel.external_id, user_id: user.id }
    expect(response.status).to eq(400)
    expect(JSON.parse(response.body)['error']).to eq(error)
  end
end

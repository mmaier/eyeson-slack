require 'rails_helper'

RSpec.describe MeetingsController, type: :controller do  

  let(:channel) { create(:channel) }
  let(:user) { create(:user, team: channel.team) }
  let(:webinar_user) { create(:user, team: channel.team, scope: SlackApi::WEBINAR_SCOPE) }

  it { should rescue_from(Eyeson::Room::ValidationFailed).with(:room_error) }
  it { should rescue_from(SlackApi::RequestFailed).with(:enter_room) }
  it { should rescue_from(SlackApi::MissingScope).with(:missing_scope) }

  it 'should redirect to login unless user present' do
    id = channel.external_id
    get :show, params: { id: id }
    redirect = login_path(
      redirect_uri: meeting_path(id: id)
    )
    expect(response).to redirect_to(redirect)
  end

  it 'should redirect to account onboarding unless user confirmed' do
    user.confirmed = false
    user.save
    account = mock('Eyeson account', new_record?: true, confirmation_url: 'https://confirm')
    Eyeson::Account.expects(:find_or_initialize_by).returns(account)
    Eyeson::Room.expects(:join).never
    get :show, params: { id: channel.external_id, user_id: user.id }
    expect(response).to redirect_to('https://confirm?callback_url='+meeting_url(user_id: user.id))
  end

  it 'should set confirmed status on user' do
    user.confirmed = false
    user.save
    account = mock('Eyeson account', new_record?: false)
    Eyeson::Account.expects(:find_or_initialize_by).returns(account)
    expects_eyeson_room_with
    expects_slack_notification
    Eyeson::Intercom.expects(:post)
    get :show, params: { id: channel.external_id, user_id: user.id }
    user.reload
    expect(user.confirmed).to eq(true)
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
    gui = 'http://test.host/gui'

    Eyeson::Room.expects(:join).with(id: channel.external_id,
                                    name: "##{channel.name}",
                                    user: user)
                              .returns(mock('Room URL', url: gui))

    expects_slack_notification

    Eyeson::Intercom.expects(:post)

    get :show, params: { id: channel.external_id, user_id: user.id }
    expect(response.status).to eq(302)
    expect(response).to redirect_to(gui)
  end

  it 'should handle eyeson api error' do
    error = 'some error'

    Eyeson::Room.expects(:join)
                .raises(Eyeson::Room::ValidationFailed, error)

    get :show, params: { id: channel.external_id, user_id: user.id }
    expect(response.status).to eq(400)
    expect(JSON.parse(response.body)['error']).to eq(error)
  end

  it 'should handle user missing scope error' do
    user = create(:user, team: channel.team, scope: ['some_scope'])

    get :show, params: { id: channel.external_id, user_id: user.id }
    redirect = login_path(
      redirect_uri: meeting_path(id: channel.external_id),
      scope: 'chat:write:user,files:write:user'
    )
    expect(response).to redirect_to(redirect)
  end

  it 'should handle user missing scope error for webinar' do
    channel.update webinar_mode: true
    get :show, params: { id: channel.external_id, user_id: user.id }
    redirect = login_path(
      redirect_uri: meeting_path(id: channel.external_id),
      scope: 'channels:history,users:read'
    )
    expect(response).to redirect_to(redirect)
  end

  it 'should handle slack missing scope error' do    
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
    gui = 'http://test.host/gui'

    expects_eyeson_room_with(gui)
    SlackApi.expects(:new).raises(SlackApi::RequestFailed)

    get :show, params: { id: channel.external_id, user_id: user.id }
    expect(response).to redirect_to(gui)
  end

  it 'should update intercom with ip address' do
    @request.headers['REMOTE_ADDR'] = '127.0.0.1'
    @request.headers['HTTP_X_FORWARDED_FOR'] = '123.123.123.123, 127.0.0.1'

    expects_eyeson_room_with
    expects_slack_notification

    Eyeson::Intercom.expects(:post).with(email: user.email,
                          ref: 'Slack',
                          fields: {
                            last_seen_ip: '123.123.123.123',
                          },
                          event: { 
                            type: 'videomeeting_slack',
                            data: {
                              team: user.team.name
                            }
                          })

    get :show, params: { id: channel.external_id, user_id: user.id }
  end
end

def expects_slack_notification(from: user)
  sn = mock('Slack Notification Service')
  sn.expects(:start)
  SlackNotificationService.expects(:new).with(from.access_token, channel).returns(sn)
end

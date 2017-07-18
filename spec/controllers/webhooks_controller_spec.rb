require 'rails_helper'

RSpec.describe WebhooksController, type: :controller do  

  let(:team) { create(:team) }
  let(:user) { create(:user, team: team) }
  let(:channel) { create(:channel, team: team, thread_id: Faker::Crypto.md5) }

  it 'should raise error on wrong api key' do
    post :create, params: { api_key: 'xyz' }
    expect(response.status).to eq(401)
  end

  it 'should return ok' do
    post :create, params: { api_key: 'test' }
    expect(response.status).to eq(200)
  end

  it 'should handle presentation_update' do
    slide   = Faker::Internet.url

    PresentationsUploadJob.expects(:perform_later).with(
      user.access_token,
      channel.id.to_s,
      slide
    )

    post :create, params: {
      api_key: 'test',
      type: 'presentation_update',
      presentation: {
        user: { id: user.email },
        room: { id: channel.external_id },
        slide: slide
      }
    }
  end

  it 'should not execute presentation_update without valid access_token' do
    user.access_token = nil
    user.save(validate: false)

    PresentationsUploadJob.expects(:perform_later).never

    post :create, params: {
      api_key: 'test',
      type: 'presentation_update',
      presentation: {
        user: { id: user.email },
        room: { id: channel.external_id },
        slide: Faker::Internet.url
      }
    }
  end

  it 'should not execute presentation_update without thread id' do
    channel.thread_id = nil
    channel.save

    PresentationsUploadJob.expects(:perform_later).never

    post :create, params: {
      api_key: 'test',
      type: 'presentation_update',
      presentation: {
        user: { id: user.email },
        room: { id: channel.external_id },
        slide: Faker::Internet.url
      }
    }
  end

  it 'should handle guest users' do
    slide   = Faker::Internet.url

    PresentationsUploadJob.expects(:perform_later).with(
      User.find(channel.initializer_id).access_token,
      channel.id.to_s,
      slide
    )

    post :create, params: {
      api_key: 'test',
      type: 'presentation_update',
      presentation: {
        user: { id: Faker::Crypto.md5 },
        room: { id: channel.external_id },
        slide: slide
      }
    }
  end

  it 'should handle broadcast_update' do
    url     = Faker::Internet.url
    channel.update webinar_mode: true

    room = mock('Room')
    room.expects(:access_key).returns('key')
    Eyeson::Room.expects(:join).with(id: channel.external_id,
                                     user: { id: 'slackbot@eyeson.team',
                                             name: 'Slack Channel' })
                .returns(room)

    BroadcastsInfoJob.expects(:perform_later).with(
      user.access_token,
      channel.id.to_s,
      url
    )

    post :create, params: {
      api_key: 'test',
      type: 'broadcast_update',
      broadcast: {
        user: { id: user.email },
        room: { id: channel.external_id },
        player_url: url,
        platform: 'youtube'
      }
    }

    channel.reload
    expect(channel.access_key).to eq('key')
    expect(channel.broadcasting).to eq(true)
  end

  it 'should not execute broadcast_update without valid access_token' do
    user.access_token = nil
    user.save(validate: false)
    
    BroadcastsInfoJob.expects(:perform_later).never

    post :create, params: {
      api_key: 'test',
      type: 'broadcast_update',
      broadcast: {
        user: { id: user.email },
        room: { id: channel.external_id },
        player_url: Faker::Internet.url,
        platform: 'youtube'
      }
    }
  end

  it 'should not execute broadcast_update in non webinar_mode' do    
    BroadcastsInfoJob.expects(:perform_later).never

    post :create, params: {
      api_key: 'test',
      type: 'broadcast_update',
      broadcast: {
        user: { id: user.email },
        room: { id: channel.external_id },
        player_url: Faker::Internet.url,
        platform: 'youtube'
      }
    }
  end

  it 'should not execute broadcast_update for other platforms than youtube' do    
    BroadcastsInfoJob.expects(:perform_later).never

    post :create, params: {
      api_key: 'test',
      type: 'broadcast_update',
      broadcast: {
        user: { id: user.email },
        room: { id: channel.external_id },
        player_url: Faker::Internet.url,
        platform: 'facebook'
      }
    }
  end

  it 'should handle broadcast_end' do
    key = Faker::Crypto.md5
    channel.update access_key: key, broadcasting: true, webinar_mode: true

    BroadcastsInfoJob.expects(:perform_later).with(
      user.access_token,
      channel.id.to_s
    )

    post :create, params: {
      api_key: 'test',
      type: 'broadcast_update',
      broadcast: {
        user: { id: user.email },
        room: { id: channel.external_id },
        player_url: nil,
        platform: 'youtube'
      }
    }
    channel.reload
    expect(channel.access_key).to eq(key)
    expect(channel.broadcasting).to eq(false)
  end

  it 'should check for valid channel' do
    SlackApi.expects(:new).never

    post :create, params: {
      api_key: 'test',
      type: 'presentation_update',
      presentation: {
        user: { id: Faker::Internet.email },
        room: { id: Faker::Code.isbn },
        slide: Faker::Internet.email
      }
    }
  end

end

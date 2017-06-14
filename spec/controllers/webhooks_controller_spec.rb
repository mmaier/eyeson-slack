require 'rails_helper'

RSpec.describe WebhooksController, type: :controller do  

  let(:team) { create(:team) }

  it 'should raise error on wrong api key' do
    post :create, params: { api_key: 'xyz' }
    expect(response.status).to eq(401)
  end

  it 'should return ok' do
    post :create, params: { api_key: 'test' }
    expect(response.status).to eq(200)
  end

  it 'should upload from url' do
    url = Faker::Internet.url
    file = Tempfile.new('upload')
    controller = WebhooksController.new

    slack_api = mock('Slack API')
    slack_api.expects(:upload_file!)
             .with(file: file, filename: "#{Time.current}.png")
            .returns({'file' => {'id' => 'xyz'}})
    slack_api.expects(:get).with('/files.sharedPublicURL', file: 'xyz')

    controller.instance_variable_set(:@slack_api, slack_api)
    controller.expects(:open).with(url).returns(file)
    controller.send(:upload_from_url, url)
  end

  it 'should handle presentation_update' do
    user    = create(:user, team: team)
    channel = create(:channel, team: team, thread_id: Faker::Crypto.md5)
    slide   = Faker::Internet.url

    SlackApi.expects(:new).with(user.access_token).returns(true)
    WebhooksController.any_instance.expects(:upload_from_url).with(slide).returns({'upload' => true})
    sn = mock('Slack Notification Service')
    sn.expects(:presentation).with({'upload' => true})
    SlackNotificationService.expects(:new).with(user.access_token, channel).returns(sn)

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

  it 'should not execute presentation_update without thread id' do
    user    = create(:user, team: team)
    channel = create(:channel, team: team)
    slide   = Faker::Internet.url
    SlackApi.expects(:new).with(user.access_token).returns(true)
    Thread.expects(:new).never
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

  it 'should handle broadcast_update' do
    user    = create(:user, team: team)
    channel = create(:channel, team: team)
    url     = Faker::Internet.url

    SlackApi.expects(:new).with(user.access_token).returns(true)
    sn = mock('Slack Notification Service')
    sn.expects(:broadcast).with(url)
    SlackNotificationService.expects(:new).with(user.access_token, channel).returns(sn)

    post :create, params: {
      api_key: 'test',
      type: 'broadcast_update',
      broadcast: {
        user: { id: user.email },
        room: { id: channel.external_id },
        url:  url
      }
    }
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

  it 'should check team user' do
    SlackApi.expects(:new).never

    post :create, params: {
      api_key: 'test',
      type: 'presentation_update',
      presentation: {
        user: { id: create(:user).external_id },
        room: { id: create(:channel, team: team).external_id },
        slide: Faker::Internet.email
      }
    }
  end

end

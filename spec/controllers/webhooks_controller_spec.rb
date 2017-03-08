require 'rails_helper'

RSpec.describe WebhooksController, type: :controller do  

  let(:team) { create(:team) }

  it 'should raise error on wrong api key' do
    post :create, params: { api_key: 'xyz' }
    expect(response.status).to eq(401)
  end

  it 'should return ok' do
    post :create, params: { api_key: team.api_key }
    expect(response.status).to eq(200)
  end

  it 'should upload from url' do
    url = Faker::Internet.url
    controller = WebhooksController.new
    controller.instance_variable_set(:@slack_api, mock('Slack API', upload_file!: nil))
    controller.expects(:open).with(url)
    controller.send(:upload_from_url, url)
  end

  it 'should post upload message' do
    preview = Faker::Internet.url
    upload = {
      'file' => {
        'url' => preview
      }
    }
    controller = WebhooksController.new
    slack_api  = mock('Slack API')
    channel = create(:channel)
    slack_api.expects(:post_message!).with(channel: channel.external_id,
                                           thread_ts: channel.thread_id,
                                           text: preview)
    controller.instance_variable_set(:@channel, channel)
    controller.instance_variable_set(:@slack_api, slack_api)
    controller.send(:post_message_for, upload)
  end

  it 'should handle presentation_update' do
    user    = create(:user, team: team)
    channel = create(:channel, team: team)
    slide   = Faker::Internet.url

    SlackApi.expects(:new).with(user.access_token)
    Thread.expects(:new)

    post :create, params: {
      api_key: team.api_key,
      type: 'presentation_update',
      presentation: {
        user: { id: user.email },
        room: { id: channel.external_id },
        slide: slide
      }
    }
  end

end

require 'rails_helper'

RSpec.describe SlackNotificationService, type: :class do

  include Rails.application.routes.url_helpers

  let(:channel) do
    create(:channel)
  end

  let(:slack) do
    SlackNotificationService.new(Faker::Crypto.md5, channel)
  end

  it 'should initialize slack api' do
    SlackApi.expects(:new).with('token')
    SlackNotificationService.new('token', build(:channel))
  end

  it 'should not send start notification for webinar' do
    channel.webinar_mode = true
    slack_api = mock('Slack Api')
    slack_api.expects(:post_message!).never
    SlackApi.expects(:new).returns(slack_api)
    slack.start
  end

  it 'should post open info' do
    slack_api = mock('Slack Api')
    url  = meeting_url(id: channel.external_id)
    text = I18n.t('.opened', url: url, scope: [:meetings, :show])
    slack_api.expects(:post_message!).with(
      channel: channel.external_id,
      text: url,
      attachments: [
        {
            color: '#9e206c',
            text: text, fallback: text,
            thumb_url: root_url + '/icon.png'
        }
      ]
    ).returns({ 'ts' => '123' })
    SlackApi.expects(:new).returns(slack_api)
    channel.expects(:thread_id=).with('123')
    channel.expects(:save)
    slack.send(:post_open_info)
  end

  it 'should post open info unless thread_id is present' do
    slack.expects(:post_open_info)
    slack.send(:start)
  end

  it 'should post join info into thread' do
    thread_id = Faker::Crypto.md5
    channel.thread_id = thread_id
    slack_api = mock('Slack Api')
    slack_api.expects(:post_message!).with(
      channel: channel.external_id,
      thread_ts: thread_id,
      text: I18n.t('.joined', url: meeting_url(id: channel.external_id),
                              scope: [:meetings, :show])
    )
    SlackApi.expects(:new).returns(slack_api)
    slack.send(:post_join_info)
  end

  it 'should post join info if thread_id is present' do
    channel.thread_id = Faker::Crypto.md5
    slack.expects(:post_join_info)
    slack.send(:start)
  end

  it 'should trigger broadcast info only when thread_id is present' do
    channel.thread_id = Faker::Crypto.md5
    slack.expects(:post_broadcast_info)
    slack.expects(:post_slides_info).never
    slack.broadcast(Faker::Internet.url)
  end

  it 'should post broadcast_info' do
    external_id = channel.external_id
    channel.external_id = external_id + '_webinar'
    channel.save
    slack_api = mock('Slack Api')
    url  = Faker::Internet.url
    text = I18n.t('.broadcast_info', scope: %i[meetings show])
    slack_api.expects(:post_message!).with(
      channel:     external_id,
      attachments: [{ color: '#9e206c', thumb_url: root_url + '/icon.png',
                      fallback: text, text: text }]
    ).returns({ 'ts' => '123' })

    slack_api.expects(:post_message!).with(
      channel:     external_id,
      thread_ts:   '123',
      text:        I18n.t('.broadcast_url', url: url, scope: %i[meetings show])
    )

    SlackApi.expects(:new).returns(slack_api)
    slack.send(:post_broadcast_info, url)
  end

  it 'should post broadcast_info without slides_info for existing thread' do
    channel.thread_id = Faker::Crypto.md5
    slack.expects(:post_broadcast_info)
    slack.expects(:post_slides_info).never
    slack.broadcast(Faker::Internet.url)
  end

  it 'should post presentation into thread' do
    channel.thread_id = Faker::Crypto.md5
    channel.save
    upload = {
      'file' => {
        'permalink_public' => Faker::Internet.url
      }
    }
    slack_api = mock('Slack Api')
    slack_api.expects(:post_message!).with(
      channel:   channel.external_id,
      thread_ts: channel.thread_id,
      text:      upload['file']['permalink_public'])
    SlackApi.expects(:new).returns(slack_api)
    slack.presentation(upload)
  end

  it 'should not post presentation without thread_id' do
    slack_api = mock('Slack Api')
    slack_api.expects(:post_message!).never
    SlackApi.expects(:new).returns(slack_api)
    slack.presentation({})
  end

  it 'should not post presentation without upload object' do
    channel.thread_id = Faker::Crypto.md5
    channel.save
    slack_api = mock('Slack Api')
    slack_api.expects(:post_message!).never
    SlackApi.expects(:new).returns(slack_api)
    slack.presentation(nil)
  end
end
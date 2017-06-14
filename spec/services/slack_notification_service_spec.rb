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

  it 'should post open info when new_command is true' do
    channel.new_command = true
    slack.expects(:post_open_info)
    slack.send(:start)
  end

  it 'should post join info into thread' do
    slack_api = mock('Slack Api')
    slack_api.expects(:post_message!).with(
      channel: channel.external_id,
      thread_ts: channel.thread_id,
      text: I18n.t('.joined', url: meeting_url(id: channel.external_id),
                              scope: [:meetings, :show])
    )
    SlackApi.expects(:new).returns(slack_api)
    slack.send(:post_join_info)
  end

  it 'should post join info when new_command is false' do
    channel.new_command = false
    slack.expects(:post_join_info)
    slack.send(:start)
  end

  it 'should post broadcast info' do
    slack_api = mock('Slack Api')
    url  = Faker::Internet.url
    slack_api.expects(:post_message!).with(
      channel: channel.external_id,
      thread_ts: channel.thread_id,
      text: url
    ).returns({ 'ts' => '123' })
    SlackApi.expects(:new).returns(slack_api)
    channel.expects(:thread_id=).never
    slack.broadcast(url)
  end

  it 'should update thread id after broadcast in webinar_mode' do
    channel.webinar_mode = true
    slack_api = mock('Slack Api')
    url  = Faker::Internet.url
    slack_api.expects(:post_message!).with(
      channel: channel.external_id,
      thread_ts: channel.thread_id,
      text: url
    ).returns({ 'ts' => '123' })
    SlackApi.expects(:new).returns(slack_api)
    channel.expects(:thread_id=).with('123')
    channel.expects(:save)
    slack.broadcast(url)
  end

  it 'should post presentation into thread' do
    channel.thread_id = Faker::Crypto.md5
    channel.save
    channel.reload
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
    channel.reload
    slack_api = mock('Slack Api')
    slack_api.expects(:post_message!).never
    SlackApi.expects(:new).returns(slack_api)
    slack.presentation(nil)
  end
end
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

  it 'should call meeting response' do
    slack.expects(:meeting_info).once
    slack.start(false)
  end

  it 'should call webinar response' do
    slack.expects(:webinar_info).once
    slack.start(true)
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
    slack.send(:meeting_info)
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
    slack.send(:meeting_info)
  end

  it 'should invite webinar speaker' do
    user = '@test'
    url  = webinar_url(id: channel.external_id)
    text = I18n.t('.speaker_invitation', url: url, scope: [:meetings, :show])
    slack_api = mock('Slack Api')
    slack_api.expects(:post_message!).with(
      channel: user,
      text: url,
      attachments: [
        {
            color: '#9e206c',
            text: text, fallback: text,
            thumb_url: root_url + '/icon.png'
        }
      ]
    )
    SlackApi.expects(:new).returns(slack_api)
    channel.expects(:new_command=).with(false)
    channel.expects(:save)
    slack.send(:post_speaker_invitation_to, user)
  end

  it 'should post to each mentioned user' do 
    channel.new_command     = true
    channel.users_mentioned = ['@test', '@test']
    slack.expects(:post_speaker_invitation_to).with('@test').twice
    slack.send(:webinar_info)
  end

  it 'should post nothing when new_command is false' do
    channel.new_command = false
    channel.expects(:users_mentioned).never
    slack.expects(:post_speaker_invitation_to).never
    slack.send(:webinar_info)
  end

  it 'should post nothing when no users were mentioned' do
    channel.new_command = true
    channel.users_mentioned = nil
    channel.expects(:users_mentioned)
    slack.expects(:post_speaker_invitation_to).never
    slack.send(:webinar_info)
  end

  it 'should post broadcast info' do
    slack_api = mock('Slack Api')
    url  = Faker::Internet.url
    text = I18n.t('.broadcast', url: url, scope: [:meetings, :show])
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
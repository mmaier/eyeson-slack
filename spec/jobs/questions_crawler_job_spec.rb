require 'rails_helper'

RSpec.describe QuestionsCrawlerJob, type: :active_job do
  let(:job) do
    QuestionsCrawlerJob.new
  end

  let(:channel) do
    create(:channel)
  end

  it 'should get_messages and requeue from channel' do
    job.expects(:requeue)
    slack = mock('Slack API')
    SlackApi.expects(:new).with(User.find(channel.initializer_id).access_token).returns(slack)
    job.expects(:get_messages).with(channel, slack)
    job.perform(channel.id.to_s)
  end

  it 'should requeue' do
    job.expects(:perform_later).with('123')
    QuestionsCrawlerJob.expects(:set).with(wait: 8.seconds).returns(job)
    job.send(:requeue, '123')
  end

  it 'should not requeue when last update was 2 hours ago' do
    channel.update updated_at: 3.hours.ago
    job.expects(:requeue).never
    job.perform(channel.id.to_s)
  end

  it 'should get messages from slack api' do
    channel.update external_id: "123_webinar"
    slack_api = mock('Slack API')
    slack_api.expects(:get).with('/channels.replies',
                                 channel: "123",
                                 thread_ts: channel.thread_id).returns({ 'messages' => [] })
    job.expects(:extract_messages).with(channel, [])
    channel.expects(:update).never
    job.send(:get_messages, channel, slack_api)
  end

  it 'should update channel queued messages' do
    slack_api = mock('Slack API')
    ts = Time.current.to_i
    slack_api.expects(:get).returns({ 'messages' => [] })
    job.expects(:extract_messages).returns(ts)
    channel.expects(:update).with(last_question_queued: ts)
    job.send(:get_messages, channel, slack_api)
  end

  it 'should queue messages' do
    messages = []
    10.times do
      m = message
      messages << m
      job.expects(:create_display_job_for).with(channel, m['user'], m['text'])
    end

    expect(job.send(:extract_messages, channel, messages)).to eq(messages.last['ts'])
  end

  it 'should queue only new messages' do
    messages = []
    10.times do |i|
      m = message
      m['ts'] = 8.seconds.from_now.to_i if i == 9
      messages << m
    end

    channel.update last_question_queued: messages[8]['ts']
    job.expects(:create_display_job_for).with(channel, messages.last['user'], messages.last['text'])
    job.send(:extract_messages, channel, messages)
  end

  it 'should queue only messages of type message' do
    messages = [message, { 'type' => 'anything' }]
    job.expects(:create_display_job_for).once
    job.send(:extract_messages, channel, messages)
  end

  it 'should create a display job' do
    user = create(:user)
    text = 'Test text'

    display_job = mock('Job')
    display_job.expects(:perform_later).with(
      channel.id.to_s,
      user.name,
      text
    )
    QuestionsDisplayJob.expects(:set).with(priority: -1).returns(display_job)

    job.send(:create_display_job_for, channel, user.external_id, text)
  end

  it 'should not create a display job when text is blank' do
    user = create(:user)
    text = ''
    QuestionsDisplayJob.expects(:set).never
    job.send(:create_display_job_for, channel, user.external_id, text)
  end

  it 'should crawl slack user information' do
    user_id = Faker::Crypto.md5
    slack = mock('Slack')
    slack.expects(:get).with('/users.info', user: user_id).returns({ 'user' => { 'name' => 'Username' } })
    SlackApi.expects(:new).with(User.find(channel.initializer_id).access_token).returns(slack)
    expect(job.send(:user_by, channel, user_id)).to eq('Username')
  end

  def message
    {
      'type' => 'message',
      'ts' => Time.current.to_i,
      'user' => Faker::Crypto.md5,
      'text' => Faker::Company.name,
    }
  end
end
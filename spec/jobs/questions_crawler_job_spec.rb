require 'rails_helper'

RSpec.describe QuestionsCrawlerJob, type: :active_job do
  let(:job) do
    QuestionsCrawlerJob.new
  end

  let(:channel) do
    create(:channel)
  end

  it 'should get_messages and requeue from channel' do
    channel.update broadcasting: true
    job.expects(:requeue)
    slack = mock('Slack API')
    SlackApi.expects(:new).with(User.find(channel.initializer_id).access_token).returns(slack)
    job.expects(:get_messages).with(channel, slack)
    job.perform(channel.id.to_s)
  end

  it 'should not requeue when channel stopped broadcasting' do
    job.expects(:requeue).never
    slack = mock('Slack API')
    SlackApi.expects(:new).with(User.find(channel.initializer_id).access_token).returns(slack)
    job.expects(:get_messages).with(channel, slack)
    job.perform(channel.id.to_s)
  end

  it 'should get messages from slack api' do
    channel.update external_id: "123_webinar"
    slack_api = mock('Slack API')
    slack_api.expects(:get).with('/channels.replies',
                                 channel: "123",
                                 thread_ts: channel.thread_id).returns({ 'messages' => [] })
    job.expects(:extract_messages).with(channel, slack_api, [], channel.next_question_displayed_at)
    channel.expects(:update).never
    job.send(:get_messages, channel, slack_api)
  end

  it 'should update channel queued messages' do
    slack_api = mock('Slack API')
    slack_api.expects(:get).returns({ 'messages' => [] })
    job.expects(:extract_messages).returns('123')
    job.send(:get_messages, channel, slack_api)
  end

  it 'should queue messages and update channel' do
    messages = []
    slack = mock('Slack')
    10.times do |i|
      m = message
      messages << m
      job.expects(:create_display_job_for).with(channel, slack, m, i * 10.seconds)
    end
    job.send(:extract_messages, channel, slack, messages, 0)
    expect(channel.last_question_queued).to eq(messages.last['ts'])
    expect(channel.next_question_displayed_at).to be_present
  end

  it 'should queue only new messages' do
    messages = []
    10.times do |i|
      m = message
      m['ts'] = QuestionsDisplayJob::INTERVAL.from_now.to_i if i == 9
      messages << m
    end
    slack =  mock('Slack')
    channel.update last_question_queued: messages[8]['ts']
    job.expects(:create_display_job_for).with(channel, slack, messages.last, 0.seconds)
    job.send(:extract_messages, channel, slack, messages, 0)
  end

  it 'should queue only messages of type message' do
    messages = [message, { 'type' => 'anything' }]
    job.expects(:create_display_job_for).once
    job.send(:extract_messages, channel, mock('Slack'), messages, 0)
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
    QuestionsDisplayJob.expects(:set).with(wait: 5.seconds, priority: -1).returns(display_job)

    job.send(:create_display_job_for, channel, mock('Slack'), message.merge('user' => user.external_id, 'text' => text), 5.seconds)
  end

  it 'should return a waiting time when display is set' do
    channel.update next_question_displayed_at: 5.seconds.from_now
    expect(job.send(:wait_for, channel.next_question_displayed_at)).to eq(15)
  end

  it 'should return a waiting time when display was in past' do
    channel.update next_question_displayed_at: 15.seconds.ago
    expect(job.send(:wait_for, channel.next_question_displayed_at)).to eq(0)
  end

  it 'should not create a display job when text is blank' do
    user = create(:user)
    QuestionsDisplayJob.expects(:set).never
    job.send(:create_display_job_for, channel, mock('Slack'), message.merge('text' => ''), 0.seconds)
  end

  it 'should crawl slack user information' do
    user_id = Faker::Crypto.md5
    slack = mock('Slack')
    slack.expects(:get).with('/users.info', user: user_id).returns({ 'user' => { 'name' => 'Username' } })
    expect(job.send(:user_by, channel, slack, user_id)).to eq('Username')
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
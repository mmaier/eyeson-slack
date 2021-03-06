require 'rails_helper'

RSpec.describe QuestionsDisplayJob, type: :active_job do
  let(:job) do
    QuestionsDisplayJob.new
  end

  let(:channel) do
    create(:channel)
  end

  it 'should perform display with channel id, username and question' do
    job.expects(:display).with(channel, 'user', 'Question')
    job.perform(channel.id.to_s, 'user', 'Question')
  end

  it 'should perform clear when last question was shown more than 10 seconds ago' do
    channel.next_question_displayed_at = 12.seconds.ago
    channel.save
    job.expects(:clear).with(channel)
    job.perform(channel.id.to_s)
  end

  it 'should not perform clear unless last question was shown more than 10 seconds ago' do
    channel.next_question_displayed_at = Time.now
    channel.save
    job.expects(:clear).never
    job.perform(channel.id.to_s)
  end

  it 'should post question to eyeson' do
    initializer  = User.find(channel.initializer_id)
    access_token = initializer.access_token

    em = mock('EM')
    em.expects(:create).with(
      type:    'chat',
      content: '/ask user: q'
    )
    Eyeson::Message.expects(:new).with(channel.access_key).returns(em)
                            
    job.send(:post_to_chat, channel, { 'name' => 'user' }, 'q')
  end

  it 'should set_layer and post_to_chat' do
    access_key = Faker::Crypto.md5
    user = {
      'name'   => Faker::Internet.user_name,
      'avatar' => Faker::Internet.url
    }
    channel.access_key = access_key
    channel.save
    layer = mock('Layer API')
    layer.expects(:create).with(insert: {
      icon: user['avatar'],
      title:   "#{user['name']}:",
      content: 'Question'
    })
    Eyeson::Layer.expects(:new).with(access_key).returns(layer)

    job.expects(:post_to_chat).with(channel, user, 'Question')

    job.expects(:perform_later).with(channel.id.to_s)
    QuestionsDisplayJob.expects(:set).with(wait: QuestionsDisplayJob::INTERVAL, priority: 1).returns(job)
                       
    job.send(:display, channel, user, 'Question')
  end

  it 'should not set_layer without access_key' do
    channel.access_key = nil
    channel.save
    Eyeson::Layer.expects(:new).never
    channel.expects(:update).never
    job.send(:set_layer, channel, 'user', 'Question')
  end

  it 'should clear' do
    access_key = Faker::Crypto.md5
    channel.access_key = access_key
    channel.save
    Eyeson::Layer.expects(:new).with(access_key).returns(mock('Layer', destroy: true))
    job.send(:clear, channel)
  end

  it 'should not clear without access_key' do
    channel.access_key = nil
    channel.save
    Eyeson::Layer.expects(:new).never
    job.send(:clear, channel)
  end
end
require 'rails_helper'

RSpec.describe QuestionsDisplayJob, type: :active_job do
  let(:job) do
    QuestionsDisplayJob.new
  end

  let(:channel) do
    create(:channel)
  end

  it 'should perform with channel id, username and question' do
    job.expects(:set_layer).with(channel, 'user', 'Question')
    job.perform(channel.id, 'user', 'Question')
  end

  it 'should re-queue unless last question was shown more than 10 seconds ago' do
    channel.last_question_at = Time.now
    channel.save
    QuestionsDisplayJob.expects(:perform_later).with(
      channel.id,
      'user',
      'Question'
    )
    job.perform(channel.id, 'user', 'Question')
  end

  it 'should set_layer' do
    access_key = Faker::Crypto.md5
    channel.access_key = access_key
    channel.save
    job.expects(:question_image).with('user', 'Question')
    layer = mock('Layer API')
    layer.expects(:create)
    Eyeson::Layer.expects(:new).with(access_key).returns(layer)
    channel.expects(:update)
    job.send(:set_layer, channel, 'user', 'Question')
  end

  it 'should not set_layer without access_key' do
    channel.access_key = nil
    channel.save
    job.expects(:question_image).never
    Eyeson::Layer.expects(:new).never
    channel.expects(:update).never
    job.send(:set_layer, channel, 'user', 'Question')
  end

  it 'should create a question image' do
    renderer = mock('Cool Renderer')
    renderer.expects(:to_url)
    CoolRenderer::QuestionImage.expects(:new).with(
      content:  'Question',
      fullname: 'user asks:'
    ).returns(renderer)
    job.send(:question_image, 'user', 'Question')
  end
end
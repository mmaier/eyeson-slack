require 'rails_helper'

RSpec.describe BroadcastsInfoJob, type: :active_job do
  let(:job) { BroadcastsInfoJob.new }
  let(:channel) { create(:channel) }

  it 'should execute notification service' do
    access_token = Faker::Crypto.md5
    url          = Faker::Internet.url

    sn = mock('Notification Service')
    sn.expects(:broadcast).with(url)
    SlackNotificationService.expects(:new).with(access_token, channel)
                            .returns(sn)

    QuestionsCrawlerJob.expects(:perform_later)

    job.perform(access_token, channel.id.to_s, url)
  end

  it 'should crawl questions' do
    SlackNotificationService.expects(:new).returns(mock('Slack Notification', broadcast: true))
    QuestionsCrawlerJob.expects(:perform_later).with(channel.id.to_s)

    job.perform(Faker::Crypto.md5, channel.id.to_s, Faker::Internet.url)
  end

  it 'should update channel updated_at' do
    SlackNotificationService.expects(:new).returns(mock('Slack Notification', broadcast: true))
    QuestionsCrawlerJob.expects(:perform_later)

    Channel.any_instance.expects(:touch)

    job.perform(Faker::Crypto.md5, channel.id.to_s, Faker::Internet.url)
  end
end
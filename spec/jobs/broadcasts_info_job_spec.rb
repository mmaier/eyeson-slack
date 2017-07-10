require 'rails_helper'

RSpec.describe BroadcastsInfoJob, type: :active_job do
  let(:job) { BroadcastsInfoJob.new }
  let(:channel) { create(:channel) }

  it 'should execute notification service and crawl questions' do
    access_token = Faker::Crypto.md5
    url          = Faker::Internet.url

    sn = mock('Notification Service')
    sn.expects(:broadcast_start).with(url)
    SlackNotificationService.expects(:new).with(access_token, channel)
                            .returns(sn)

    QuestionsCrawlerJob.expects(:perform_later).with(channel.id.to_s)

    job.perform(access_token, channel.id.to_s, url)
  end

  it 'should post broadcast end info' do
    access_token = Faker::Crypto.md5

    sn = mock('Notification Service')
    sn.expects(:broadcast_end)
    SlackNotificationService.expects(:new).with(access_token, channel)
                            .returns(sn)

    job.perform(access_token, channel.id.to_s)
  end
end
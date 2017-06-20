require 'rails_helper'

RSpec.describe BroadcastsInfoJob, type: :active_job do
  let(:job) { BroadcastsInfoJob.new }

  it 'should execute notification service' do
    access_token = Faker::Crypto.md5
    channel      = create(:channel)
    url          = Faker::Internet.url

    sn = mock('Notification Service')
    sn.expects(:broadcast).with(url)
    SlackNotificationService.expects(:new).with(access_token, channel)
                            .returns(sn)

    job.perform(access_token, channel.id.to_s, url)
  end
end
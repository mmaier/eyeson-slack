require 'rails_helper'

RSpec.describe PresentationsUploadJob, type: :active_job do
  let(:job) { PresentationsUploadJob.new }

  let(:channel) { create(:channel, thread_id: Faker::Crypto.md5) }

  it 'should upload from url' do
    access_token = Faker::Crypto.md5
    url = Faker::Internet.url
    file = Tempfile.new('upload')

    job.expects(:open).with(url).returns(file)

    slack_api = mock('Slack API')
    slack_api.expects(:upload_file!)
             .with(file: file, filename: "#{Time.current}.png")
            .returns({'file' => {'id' => 'xyz'}})
    slack_api.expects(:get).with('/files.sharedPublicURL', file: 'xyz')
    SlackApi.expects(:new).with(access_token).returns(slack_api)

    job.send(:upload, access_token, url)
  end

  it 'should not execute without thread_id' do
    channel.thread_id = nil
    channel.save

    SlackApi.expects(:new).never

    job.perform(Faker::Crypto.md5, channel.id.to_s, Faker::Internet.url)
  end

  it 'should handle presentation_update' do
    access_token = Faker::Crypto.md5
    slide   = Faker::Internet.url

    upload = mock('Upload')
    job.expects(:upload).with(access_token, slide).returns(upload)

    sn = mock('Notification Service')
    sn.expects(:presentation).with(upload)
    SlackNotificationService.expects(:new).with(access_token, channel).returns(sn)

    job.perform(access_token, channel.id.to_s, slide)
  end
end
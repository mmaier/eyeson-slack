# Uploads presentation slides to slack channel
class PresentationsUploadJob < ApplicationJob
  require 'open-uri'

  queue_as :default

  def perform(*args)
    access_token = args[0]
    channel      = Channel.find(args[1])
    slide_url    = args[2]

    return if channel.thread_id.blank?

    SlackNotificationService.new(access_token, channel)
                            .presentation(
                              upload(access_token, slide_url)
                            )
  end

  private

  def upload(access_token, url)
    slack_api = SlackApi.new(access_token)
    file   = open(url)
    upload = slack_api.upload_file!(file: file,
                                    filename: "#{Time.current}.png")
    slack_api.get('/files.sharedPublicURL', file: upload['file']['id'])
  end
end

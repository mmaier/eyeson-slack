# Uploads YouTube player to slack channel
class BroadcastsInfoJob < ApplicationJob
  queue_as :default

  def perform(*args)
    access_token  = args[0]
    channel       = Channel.find(args[1])
    broadcast_url = args[2]

    if broadcast_url.nil?
      SlackNotificationService.new(access_token, channel).broadcast_end
    else
      SlackNotificationService.new(access_token, channel)
                              .broadcast_start(broadcast_url)

      QuestionsCrawlerJob.perform_later(channel.id.to_s)
    end
  end
end

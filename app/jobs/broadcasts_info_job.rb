# Uploads YouTube player to slack channel
class BroadcastsInfoJob < ApplicationJob
  queue_as :default

  def perform(*args)
    access_token  = args[0]
    channel       = Channel.find(args[1])
    broadcast_url = args[2]

    SlackNotificationService.new(access_token, channel)
                            .broadcast(broadcast_url)
  end
end

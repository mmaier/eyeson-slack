# Uploads YouTube player to slack channel
class BroadcastsInfoJob < ApplicationJob
  queue_as :default

  def perform(*args)
    access_token  = args[0]
    channel       = Channel.find(args[1])
    broadcast_url = args[2]

    SlackNotificationService.new(access_token, channel)
                            .broadcast(broadcast_url)

    crawl_webinar_questions(channel)
  end

  private

  def crawl_webinar_questions(channel)
    return if channel.last_question_queued_at &&
              channel.last_question_queued_at > 2.hours.ago

    QuestionsCrawlerJob.set(wait: QuestionsDisplayJob::INTERVAL)
                       .perform_later(channel.id.to_s)
  end
end

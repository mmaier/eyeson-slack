# crawles all questions from a slack thread
class QuestionsCrawlerJob < ApplicationJob
  queue_as :default

  def perform(*args)
    channel = Channel.find(args[0])

    return if channel.updated_at < 2.hours.ago

    initializer = User.find(channel.initializer_id)
    slack_api   = SlackApi.new(initializer.access_token)

    get_messages(channel, slack_api)

    requeue(args[0])
  end

  private

  def requeue(channel_id)
    QuestionsCrawlerJob.set(wait: 10.seconds)
                       .perform_later(channel_id)
  end

  def get_messages(channel, slack_api)
    messages = slack_api.get('/channels.replies',
                             channel: channel.external_id.gsub('_webinar', ''),
                             thread_ts: channel.thread_id)

    last_message_ts = extract_messages(channel, messages['messages'])

    return if last_message_ts.nil?
    channel.update last_question_queued: last_message_ts
  end

  def extract_messages(channel, messages)
    last_message_ts = nil

    messages.each do |m|
      next if m['type'] != 'message' || m['bot_id'].present?
      last_message_ts = m['ts'].to_f
      next if last_message_ts <= channel.last_question_queued.to_f
      create_display_job_for(channel, m['user'], m['text'])
    end

    last_message_ts
  end

  def create_display_job_for(channel, user_id, text)
    return if text.blank?
    QuestionsDisplayJob.set(priority: -1)
                       .perform_later(channel.id.to_s,
                                      user_by(channel, user_id),
                                      text)
  end

  def user_by(channel, external_id)
    u = User.find_by(external_id: external_id).try(:name)
    return u if u.present?
    slack_api = SlackApi.new(channel.executing_user(external_id).access_token)
    slack_api.get('/users.info', user: external_id)['user']['name']
  end
end

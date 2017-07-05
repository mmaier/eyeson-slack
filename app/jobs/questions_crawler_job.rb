# crawles all questions from a slack thread
class QuestionsCrawlerJob < ApplicationJob
  queue_as :default

  def perform(*args)
    channel = Channel.find(args[0])

    return if channel.last_question_queued_at &&
              channel.last_question_queued_at < 2.hours.ago

    initializer = User.find(channel.initializer_id)
    slack_api   = SlackApi.new(initializer.access_token)

    get_messages(channel, slack_api)

    requeue(args[0])
  end

  private

  def requeue(channel_id)
    QuestionsCrawlerJob.set(wait: QuestionsDisplayJob::INTERVAL)
                       .perform_later(channel_id)
  end

  def get_messages(channel, slack_api)
    messages = slack_api.get('/channels.replies',
                             channel: channel.external_id.gsub('_webinar', ''),
                             thread_ts: channel.thread_id)

    last_message_ts = extract_messages(channel, messages['messages'])

    return if last_message_ts.nil?
    channel.update(last_question_queued: last_message_ts,
                   last_question_queued_at: Time.current)
  end

  def extract_messages(channel, messages)
    last_message_ts = nil
    wait = wait_for(channel.last_question_displayed_at)

    messages.each do |m|
      next unless show_message?(m)
      last_message_ts = m['ts'].to_f
      next if last_message_ts <= channel.last_question_queued.to_f
      create_display_job_for(channel, m['user'], m['text'], wait)
      wait += QuestionsDisplayJob::INTERVAL
    end

    last_message_ts
  end

  def wait_for(last_question_displayed_at)
    return 0.seconds unless last_question_displayed_at
    (Time.current - last_question_displayed_at).to_i
  end

  def show_message?(m)
    m['type'] == 'message' && m['bot_id'].blank?
  end

  def create_display_job_for(channel, user_id, text, wait)
    return if text.blank?
    QuestionsDisplayJob.set(
      wait: wait,
      priority: -1
    ).perform_later(channel.id.to_s,
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

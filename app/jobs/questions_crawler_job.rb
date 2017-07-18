# crawles all questions from a slack thread
class QuestionsCrawlerJob < ApplicationJob
  queue_as :default

  def perform(*args)
    channel = Channel.find(args[0])

    initializer = User.find(channel.initializer_id)
    slack_api   = SlackApi.new(initializer.access_token)

    get_messages(channel, slack_api)

    requeue(channel) if channel.broadcasting?
  end

  private

  def requeue(channel)
    QuestionsCrawlerJob.set(wait: QuestionsDisplayJob::INTERVAL)
                       .perform_later(channel.id.to_s)
  end

  def get_messages(channel, slack_api)
    messages = slack_api.get('/channels.replies',
                             channel: channel.external_id.gsub('_webinar', ''),
                             thread_ts: channel.thread_id)

    extract_messages(channel,
                     slack_api,
                     messages['messages'],
                     channel.next_question_displayed_at)
  end

  # rubocop:disable Metrics/ParameterLists
  def extract_messages(channel, slack_api, messages,
                       next_message, last_message = nil, wait = nil)
    messages.each do |m|
      last_message = message_queued?(channel, m)
      next if last_message.nil?
      wait = wait_for(next_message)
      create_display_job_for(channel, slack_api, m, wait.seconds)
      next_message = wait.seconds.from_now
    end

    return if wait.nil?
    channel.update(last_question_queued:       last_message,
                   next_question_displayed_at: next_message)
  end

  def wait_for(next_message)
    time_to_next_question = (
      next_message.to_i - Time.current.to_i
    )
    [time_to_next_question + QuestionsDisplayJob::INTERVAL, 0].max
  end

  def show_message?(message)
    message['type'] == 'message' && message['bot_id'].blank?
  end

  def message_queued?(channel, message)
    ts = message['ts'].to_f
    return unless show_message?(message)
    return if ts <= channel.last_question_queued.to_f
    ts
  end

  def create_display_job_for(channel, slack_api, message, wait)
    text = message['text']
    return if text.blank?
    QuestionsDisplayJob.set(
      wait: wait,
      priority: -1
    ).perform_later(channel.id.to_s,
                    user_by(channel, slack_api, message['user']),
                    text)
  end

  def user_by(_channel, slack_api, external_id)
    u = User.find_by(external_id: external_id)
    return { 'name' => u.name, 'avatar' => u.avatar } if u.present?
    slack_user = slack_api.get('/users.info', user: external_id)['user']
    {
      'name'   => slack_user['name'],
      'avatar' => slack_user['profile']['image_32']
    }
  end
end

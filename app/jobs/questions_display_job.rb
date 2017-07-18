# Handles question display in webinar room
class QuestionsDisplayJob < ApplicationJob
  queue_as :default

  INTERVAL = 10.seconds.freeze

  def perform(*args)
    channel  = Channel.find(args[0])
    user     = args[1]
    question = args[2]

    if question.present?
      display(channel, user, question)
    elsif clearable?(channel)
      clear(channel)
    end
  end

  private

  def clearable?(channel)
    channel.next_question_displayed_at < QuestionsDisplayJob::INTERVAL.ago
  end

  def display(channel, user, question)
    set_layer(channel, user, question)
    post_to_chat(channel, user, question)
  end

  def clear(channel)
    return if channel.access_key.blank?
    Eyeson::Layer.new(channel.access_key).destroy
  end

  def set_layer(channel, user, question)
    return if channel.access_key.blank?
    layer = Eyeson::Layer.new(channel.access_key)
    layer.create(insert: {
                   icon:    user['avatar'],
                   title:   "#{user['name']}:",
                   content: question.truncate(280)
                 })
    QuestionsDisplayJob.set(wait: QuestionsDisplayJob::INTERVAL, priority: 1)
                       .perform_later(channel.id.to_s)
  end

  def post_to_chat(channel, user, question)
    Eyeson::Message.new(channel.access_key).create(
      type:    'chat',
      content: '/ask ' + user['name'] + ': ' + question
    )
  end
end

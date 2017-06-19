# Handles question display in webinar room
class QuestionsDisplayJob < ApplicationJob
  queue_as :default

  def perform(*args)
    channel  = Channel.find(args[0])
    username = args[1]
    question = args[2]

    if question && question_active?(channel)
      requeue(channel, username, question)
    elsif question
      set_layer(channel, username, question)
    elsif clearable?(channel)
      clear_layer(channel)
    end
  end

  private

  def question_active?(channel)
    channel.last_question_at && channel.last_question_at > 10.seconds.ago
  end

  def clearable?(channel)
    channel.last_question_at && channel.last_question_at < 10.seconds.ago
  end

  def requeue(channel, username, question)
    QuestionsDisplayJob.perform_later(channel.id,
                                      username,
                                      question)
  end

  def set_layer(channel, username, question)
    return if channel.access_key.blank?
    layer = Eyeson::Layer.new(channel.access_key)
    layer.create(url: question_image(username, question))
    channel.update last_question_at: Time.current
    QuestionsDisplayJob.set(wait: 10.seconds).perform_later(channel.id.to_s)
  end

  def clear_layer(channel)
    return if channel.access_key.blank?
    Eyeson::Layer.new(channel.access_key).destroy
    channel.update last_question_at: nil
  end

  def question_image(username, question)
    CoolRenderer::QuestionImage.new(
      content:  question,
      fullname: username + ' asks:'
    ).to_url
  end
end
# Handles question display in webinar room
class QuestionsDisplayJob < ApplicationJob
  queue_as :default

  def perform(*args)
    channel  = Channel.find(args[0])
    username = args[1]
    question = args[2]

    if channel.last_question_at && channel.last_question_at > 10.seconds.ago
      QuestionsDisplayJob.perform_later(channel.id,
                                        username,
                                        question)
    else
      set_layer(channel, username, question)
    end
  end

  private

  def requeue; end

  def set_layer(channel, username, question)
    return if channel.access_key.blank?
    layer = Eyeson::Layer.new(channel.access_key)
    layer.create(url: question_image(username, question))
    channel.update last_question_at: Time.current
  end

  def question_image(username, question)
    CoolRenderer::QuestionImage.new(
      content:  question,
      fullname: username + ' asks:'
    ).to_url
  end
end

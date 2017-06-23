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
      display(channel, username, question)
    elsif clearable?(channel)
      clear(channel)
    end
  end

  private

  def question_active?(channel)
    channel.last_question_at && channel.last_question_at >= 10.seconds.ago
  end

  def clearable?(channel)
    channel.last_question_at && channel.last_question_at < 10.seconds.ago
  end

  def requeue(channel, username, question)
    QuestionsDisplayJob.set(priority: -2).perform_later(channel.id.to_s,
                                                        username,
                                                        question)
  end

  def display(channel, username, question)
    set_layer(channel, username, question)
    post_to_chat(channel, username, question)
  end

  def clear(channel)
    return if channel.access_key.blank?
    channel.update last_question_at: nil
    Eyeson::Layer.new(channel.access_key).destroy
  end

  def set_layer(channel, username, question)
    return if channel.access_key.blank?
    channel.update last_question_at: Time.current
    layer = Eyeson::Layer.new(channel.access_key)
    layer.create(url: question_image(username, question))
    QuestionsDisplayJob.set(wait: 10.seconds, priority: 1)
                       .perform_later(channel.id.to_s)
  end

  def question_image(username, question)
    CoolRenderer::QuestionImage.new(
      fullname: "@#{username}:",
      content:  question.truncate(280)
    ).to_url
  end

  def post_to_chat(channel, username, question)
    Eyeson::Message.new(channel.access_key).create(
      type:    'chat',
      content: '/ask @' + username + ': ' + question
    )

    access_token = User.find(channel.initializer_id).try(:access_token)
    return if access_token.nil?
    SlackNotificationService.new(access_token, channel)
                            .question(username, question)
  end
end

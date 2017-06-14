module CoolRenderer
  # Question Image
  class QuestionImage < BaseImage
    def initialize(question)
      @question = question
    end

    def to_url
      request 'html_tweet', @question.merge(position: 'center')
    end
  end
end

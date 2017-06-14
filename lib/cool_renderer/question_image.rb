module CoolRenderer
  # Question Image
  class QuestionImage < BaseImage
    def initialize(question)
      @question = question
    end

    def to_url
      request 'html_tweet', @question
    end
  end
end

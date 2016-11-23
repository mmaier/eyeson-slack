# Application Controller
class ApplicationController < ActionController::API
  private

  def slack_api
    @slack_api = SlackApi.new
  end
end

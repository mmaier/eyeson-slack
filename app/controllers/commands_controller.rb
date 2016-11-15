# Executes slack command
class CommandsController < ApplicationController
  before_action :verify_slack_token

  def respond
    # Slack response
    username = params.require(:user_name)
    url = meeting_url(id: params.require(:channel_id))
    response = {
      response_type: :in_channel,
      color: :good,
      text: "#{username} created a videomeeting: #{url}"
    }
    render json: response
  end

  private

  def verify_slack_token
    return if params.require(:token) == APP_CONFIG['slack_token']
    render json: {
      text: 'Verification not correct'
    }
  end
end

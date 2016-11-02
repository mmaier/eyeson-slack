# Executes slack command
class CommandsController < ApplicationController
  before_action :verify_slack_token

  def respond
    # Create new room
    channel = {
      id:   params.require(:channel_id),
      name: params.require(:channel_name)
    }
    Room.new(channel)

    # Slack response
    response = {
      response_type: :in_channel,
      color: :good,
      text: "#{@user[:name]} created a videomeeting: #{meeting_url(id: @channel[:id])}"
    }
    render json: response
  end

  private

  def verify_slack_token
    return if params[:token] == APP_CONFIG['slack_token']
    render json: {
      text: 'Are you trying to hack us? Seems like the verification token was not correct...'
    }
  end
end

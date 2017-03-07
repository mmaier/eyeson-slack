# Webhook handling
class WebhooksController < ApplicationController
  before_action :valid_api_key!

  def create
    send(params[:type])
    head :ok
  end

  private

  def valid_api_key!
    @team = Team.find_by(api_key: params.require(:api_key))
    head :unauthorized unless @team.present?
  end

  def presentation_update
    channel = Channel.find_by(external_id: presentation_params[:room_id])
    access_token = User.find_by(email: presentation_params[:user_id])
                       .try(:access_token)
    slack_api = SlackApi.new(access_token)
    slack_api.request('/chat.postMessage',
                      channel:   channel.external_id,
                      text:      'Test: Slide...',
                      thread_ts: channel.thread_id)
  end

  def room_params
    params.require(:room)
  end

  def presentation_params
    presentation = params.require(:presentation)
    {
      slide:   presentation.require(:slide),
      room_id: presentation.require(:room).require(:id),
      user_id: presentation.require(:user).require(:id)
    }
  end
end

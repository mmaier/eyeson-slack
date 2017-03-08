# Webhook handling
class WebhooksController < ApplicationController

  require 'open-uri'
  
  before_action :valid_api_key!

  def create
    send(params[:type]) if params[:type].present?
    head :ok
  end

  private

  def valid_api_key!
    @team = Team.find_by(api_key: params.require(:api_key))
    head :unauthorized unless @team.present?
  end

  def presentation_update
    @channel      = Channel.find_by(external_id: presentation_params[:room_id])
    access_token  = User.find_by(email: presentation_params[:user_id])
                        .try(:access_token)

    return unless access_token.present?

    @slack_api = SlackApi.new(access_token)

    #Thread.new do
      upload = upload_from_url(presentation_params[:slide])
      post_message_for(upload)
    #end
  end

  def upload_from_url(url)
    file = open(url)
    @slack_api.upload_file!(content: file.read,
                            filename: "#{Time.current}.png")
  end

  def post_message_for(upload)
    @slack_api.post_message!(channel: @channel.external_id,
                             thread_ts: @channel.thread_id,
                             text: 'Presentation slide',
                             attachments: [
                               {
                                 image_url: upload['file']['thumb_360']
                               }
                             ])
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

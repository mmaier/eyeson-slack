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
    return if params.require(:api_key) == Rails.application
              .secrets.eyeson_api_key
    head :unauthorized
  end

  def presentation_update
    @channel = Channel.find_by(external_id: presentation_params[:room_id])

    return if @channel.blank?

    access_token = User.find_by(team: @channel.team,
                                email: presentation_params[:user_id])
                       .try(:access_token)

    return if access_token.blank?

    @slack_api = SlackApi.new(access_token)

    upload_slide
  end

  def upload_slide
    Thread.new do
      upload = upload_from_url(presentation_params[:slide])
      post_message_for(upload)
    end
  end

  def upload_from_url(url)
    file   = open(url)
    upload = @slack_api.upload_file!(file: file,
                                     filename: "#{Time.current}.png")
    @slack_api.get('/files.sharedPublicURL', file: upload['file']['id'])
  end

  def post_message_for(upload)
    @slack_api.post_message!(channel: @channel.external_id,
                             thread_ts: @channel.thread_id,
                             text: upload['file']['permalink_public'])
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

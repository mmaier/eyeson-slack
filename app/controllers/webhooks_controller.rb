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
    slack_api_from(presentation_params)
    return if @slack_api.nil?
    return if @channel.thread_id.blank?
    upload = upload_from_url(presentation_params[:slide])
    SlackNotificationService.new(@access_token, @channel)
                            .presentation(upload)
  end

  def broadcast_update
    slack_api_from(broadcast_params)
    return if @slack_api.nil?
    SlackNotificationService.new(@access_token, @channel)
                            .broadcast(broadcast_params[:url])
  end

  def slack_api_from(params)
    @channel = Channel.find_by(external_id: params[:room_id])

    return if @channel.blank?

    @access_token = User.find_by(team: @channel.team,
                                 email: params[:user_id])
                        .try(:access_token)

    return if @access_token.blank?

    @slack_api = SlackApi.new(@access_token)
  end

  def upload_from_url(url)
    file   = open(url)
    upload = @slack_api.upload_file!(file: file,
                                     filename: "#{Time.current}.png")
    @slack_api.get('/files.sharedPublicURL', file: upload['file']['id'])
  end

  def presentation_params
    presentation = params.require(:presentation)
    {
      slide:   presentation.require(:slide),
      room_id: presentation.require(:room).require(:id),
      user_id: presentation.require(:user).require(:id)
    }
  end

  def broadcast_params
    broadcast = params.require(:broadcast)
    {
      url:   broadcast.require(:url),
      room_id: broadcast.require(:room).require(:id),
      user_id: broadcast.require(:user).require(:id)
    }
  end
end

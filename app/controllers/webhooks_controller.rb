# Webhook handling
class WebhooksController < ApplicationController
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

  def room_update
    return unless params[:room][:shutdown] == 'true'
    @channel = Channel.find_by(external_id: params[:room].require(:id))
    return unless @channel.webinar_mode?
    @channel.update access_key: nil, last_question_queued_at: 2.hours.ago
  end

  def presentation_update
    access_token = slack_key_from(presentation_params)
    return if access_token.nil?
    return if @channel.thread_id.blank?
    PresentationsUploadJob.perform_later(
      access_token,
      @channel.id.to_s,
      presentation_params[:slide]
    )
  end

  def broadcast_update
    access_token = slack_key_from(broadcast_params)
    return if access_token.nil? || !@channel.webinar_mode?
    BroadcastsInfoJob.perform_later(
      access_token,
      @channel.id.to_s,
      broadcast_params[:url]
    )
  end

  def slack_key_from(params)
    @channel = Channel.find_by(external_id: params[:room_id])
    return if @channel.blank?
    @channel.executing_user(params[:user_id]).try(:access_token)
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

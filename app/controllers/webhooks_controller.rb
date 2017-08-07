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

  def presentation_update
    presentation_params = params.require(:presentation)
    @access_token = slack_key_from(presentation_params)
    return if @access_token.nil?
    return if @channel.thread_id.blank?
    PresentationsUploadJob.perform_later(
      @access_token,
      @channel.id.to_s,
      presentation_params.require(:slide)
    )
  end

  def broadcast_update
    broadcast_params = params.require(:broadcast)
    return unless broadcast_params.require(:platform) == 'youtube'

    @access_token = slack_key_from(broadcast_params)
    return if @access_token.nil? || !@channel.webinar_mode?

    if broadcast_params[:player_url].blank?
      broadcast_end
    else
      broadcast_start
    end
  end

  def recording_update
    recording_params = params.require(:recording)
    @access_token    = slack_key_from(recording_params)
    return if @access_token.nil?
    SlackNotificationService.new(
      @access_token,
      @channel
    ).recording_uploaded(
      recording_url(id: recording_params.require(:id))
    )
  end

  def broadcast_start
    slack_user = Eyeson::Room.join(id: @channel.external_id,
                                   user: { id: 'slackbot@eyeson.team',
                                           name: 'Slack Channel' })
    @channel.update(access_key:   slack_user.access_key,
                    broadcasting: true)

    BroadcastsInfoJob.perform_later(
      @access_token,
      @channel.id.to_s,
      params.require(:broadcast).require(:player_url)
    )
  end

  def broadcast_end
    @channel.update broadcasting: false
    BroadcastsInfoJob.perform_later(
      @access_token,
      @channel.id.to_s
    )
  end

  def slack_key_from(params)
    @channel = Channel.find_by(
      external_id: params.require(:room).require(:id)
    )
    return if @channel.blank?
    executing_user(
      params.require(:user).require(:id)
    ).try(:access_token)
  end

  def executing_user(external_id)
    User.find_by(team:  @channel.team,
                 email: external_id) ||
      User.find(@channel.initializer_id)
  end
end

# Executes slack command
class CommandsController < ApplicationController
  before_action :valid_slack_token!, only: [:create]
  before_action :team_exists!, only: [:create]
  before_action :setup_channel!, only: [:create]

  def create
    response = if params[:text] == 'help'
                 help_response
               elsif params[:text].try(:start_with?, 'webinar')
                 webinar_response
               elsif params[:text].try(:start_with?, 'ask')
                 webinar_question
               else
                 meeting_response
               end
    render json: response
  end

  private

  def valid_slack_token!
    return if params.require(:token) == Rails.application
                                             .secrets.slack_token
    render json: {
      text: I18n.t('.invalid_slack_token', scope: [:commands])
    }
  end

  def team_exists!
    @team = Team.find_by(external_id: params.require(:team_id))
    invalid_setup_response if @team.blank?
  end

  def help_response
    {
      text: I18n.t('.help',
                   url: Rails.configuration.services['faq_url'],
                   scope: [:commands])
    }
  end

  def meeting_response
    url = meeting_url(id: params.require(:channel_id))
    {
      text: I18n.t('.meeting_response',
                   url: url,
                   scope: [:commands])
    }
  end

  def webinar_response
    url = webinar_url(id: params.require(:channel_id))
    {
      text: I18n.t('.webinar_response',
                   url:   url,
                   users: @channel.users_mentioned
                                  .to_a.map { |u| u.split('|').last }
                                  .join(', '),
                   scope: [:commands])
    }
  end

  def webinar_question
    return unless @channel.access_key.present?
    layer = Eyeson::Layer.new(@channel.access_key)
    layer.create(url: question_image)
  end

  def question_image
    CoolRenderer::QuestionImage.new(
      content: params[:text].gsub('ask ', ''),
      fullname: params[:user_name],
      username: params[:channel_name]
    ).to_url
  end

  def setup_channel!
    @channel = @team.channels.find_or_initialize_by(
      external_id: params.require(:channel_id)
    )
    @channel.name = params.require(:channel_name)
    @channel.new_command     = true
    @channel.users_mentioned = params[:text].try(:scan, /<@([A-Za-z0-9|.]+)>/)
                                            .try(:flatten)
    @channel.save!
  end

  def invalid_setup_response
    response = {
      text: I18n.t('.invalid_setup',
                   url: setup_url,
                   scope: [:commands])
    }
    render json: response
  end
end

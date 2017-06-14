# Executes slack command
class CommandsController < ApplicationController
  before_action :valid_slack_token!
  before_action :help?
  before_action :team_exists!
  before_action :setup_channel!

  def create
    response = if webinar?
                 webinar_response
               elsif question?
                 question_response
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

  def help?
    return unless params[:text].try(:start_with?, 'help') == true
    render json: {
      text: I18n.t('.help',
                   url: Rails.configuration.services['faq_url'],
                   scope: [:commands])
    }
  end

  def team_exists!
    @team = Team.find_by(external_id: params.require(:team_id))
    invalid_setup_response if @team.blank?
  end

  def webinar?
    params[:text].try(:start_with?, 'webinar') == true
  end

  def question?
    params[:text].try(:start_with?, 'ask') == true
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
                   scope: [:commands])
    }
  end

  def question_response
    return if @channel.access_key.blank?
    layer = Eyeson::Layer.new(@channel.access_key)
    layer.create(url: question_image)
    webinar_question
  end

  def webinar_question
    params[:text].gsub('ask ', '')
  end

  def question_image
    CoolRenderer::QuestionImage.new(
      content:  webinar_question,
      fullname: params[:user_name] + ' asks:'
    ).to_url
  end

  def setup_channel!
    @channel = @team.channels.find_or_initialize_by(
      external_id: params.require(:channel_id)
    )
    unless question?
      @channel.name = params.require(:channel_name)
      @channel.thread_id    = nil
      @channel.webinar_mode = webinar?
    end
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

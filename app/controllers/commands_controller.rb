# Executes slack command
class CommandsController < ApplicationController
  before_action :valid_slack_token!
  before_action :help?
  before_action :team_exists!
  before_action :setup_channel!

  def create
    response = if meeting?
                 meeting_response
               elsif webinar?
                 webinar_response
               elsif question?
                 question_response
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
    if params[:text].blank? ||
       params[:text] == 'help' ||
       question? && webinar_question.blank?
      render json: {
        text: I18n.t('.help',
                     url: Rails.configuration.services['faq_url'],
                     scope: [:commands])
      }
    end
  end

  def team_exists!
    @team = Team.find_by(external_id: params.require(:team_id))
    invalid_setup_response if @team.blank?
  end

  def meeting?
    params[:text].try(:start_with?, 'meeting') == true
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
    QuestionsDisplayJob.perform_later(@channel.id.to_s,
                                      params[:user_name],
                                      webinar_question.strip)
    {
      text: I18n.t('.question_response',
                   question: webinar_question.strip,
                   scope: [:commands])
    }
  end

  def webinar_question
    params[:text].gsub('ask', '')
  end

  def setup_channel!
    @channel = Channel.find_or_initialize_by(
      team: @team,
      external_id: params.require(:channel_id) + (webinar? ? '_webinar' : '')
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

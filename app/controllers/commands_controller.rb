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
    return unless params[:text] == 'help'
    render json: {
      text: I18n.t('.help',
                   url: Rails.configuration.services['faq_url'],
                   scope: [:commands])
    }
  end

  def team_exists!
    @team = Team.find_by(external_id: params.require(:team_id))

    return if @team.present?

    render json: {
      text: I18n.t('.invalid_setup',
                   url: setup_url,
                   scope: [:commands])
    }
  end

  def meeting?
    params[:command] == command
  end

  def webinar?
    params[:command] == command + '-webinar'
  end

  def question?
    params[:command] == command + '-ask'
  end

  def command
    '/eyeson' << ("-#{Rails.env}" unless Rails.env.production?)
  end

  def meeting_response
    url = meeting_url(id: @channel.external_id)
    {
      text: I18n.t('.meeting_response',
                   url: url,
                   scope: [:commands])
    }
  end

  def webinar_response
    url = webinar_url(id: @channel.external_id)
    {
      text: I18n.t('.webinar_response',
                   url:   url,
                   scope: [:commands])
    }
  end

  def question_response
    unless @channel.persisted?
      return { text: I18n.t('.question_failed', scope: [:commands]) }
    end

    return if params[:text].blank?

    create_display_job

    { text: I18n.t('.question_response',
                   question: params[:text],
                   scope: [:commands]) }
  end

  def setup_channel!
    external_id = params.require(:channel_id)
    external_id << '_webinar' if webinar? || question?
    @channel = Channel.find_or_initialize_by(team: @team,
                                             external_id: external_id)

    return if question?

    @channel.name         = params.require(:channel_name)
    @channel.thread_id    = nil
    @channel.webinar_mode = webinar?
    @channel.save!
  end

  def create_display_job
    QuestionsDisplayJob.set(priority: -1)
                       .perform_later(@channel.id.to_s,
                                      params[:user_name],
                                      params[:text])
  end
end

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

    render json: { text: I18n.t('.invalid_setup',
                                url: setup_url,
                                scope: [:commands]) }
  end

  def meeting?
    params[:command] == command
  end

  def webinar?
    params[:command] == command + '-webinar'
  end

  def command
    pattern = '/eyeson'
    return pattern if Rails.env.production?
    pattern << "-#{Rails.env}"
  end

  def meeting_response
    url = meeting_url(id: @channel.external_id)
    { text: I18n.t('.meeting_response',
                   url: url,
                   scope: [:commands]) }
  end

  def webinar_response
    url = webinar_url(id: @channel.external_id)
    { text: I18n.t('.webinar_response',
                   url:   url,
                   scope: [:commands]) }
  end

  def setup_channel!
    external_id = params.require(:channel_id)
    external_id << '_webinar' if webinar?
    @channel = Channel.find_or_initialize_by(team: @team,
                                             external_id: external_id)

    @channel.name           = params.require(:channel_name)
    @channel.initializer_id = User.find_by(team: @team,
                                           external_id: params[:user_id]).id
    @channel.thread_id      = nil
    @channel.webinar_mode   = webinar?
    @channel.save!
  end
end

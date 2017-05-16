# Executes slack command
class CommandsController < ApplicationController
  before_action :valid_slack_token!, only: [:create]
  before_action :team_exists!, only: [:create]
  before_action :setup_channel!, only: [:create]

  def create
    send 'command_' + params.require(:command)
  end

  private

  def command_eyeson
    response = if 'help' == params[:text]
                 help_response
               else
                 meeting_response
               end
    render json: response
  end

  def command_question
    access_token = nil
    # TODO: Which access_token to take?
    layer = Eyeson::Layer.new(access_token)
    image_url = nil
    # TODO: Generate image url
    layer.create(url: image_url)
    head :ok
  end

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
      text: I18n.t('.response',
                   url: url,
                   scope: [:commands])
    }
  end

  def setup_channel!
    @channel = @team.channels.find_or_initialize_by(
      external_id: params.require(:channel_id)
    )
    @channel.name = params.require(:channel_name)
    @channel.new_command = true
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

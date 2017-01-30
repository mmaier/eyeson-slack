# Executes slack command
class CommandsController < ApplicationController
  before_action :valid_slack_token!, only: [:create]
  before_action :team_exists!, only: [:create]
  before_action :setup_channel!, only: [:create]

  def create
    # Send immediate response to slack (must be <300ms)
    if 'help' == params[:text]
      render json: help_response
    else
      render json: meeting_response
    end
  end

  private

  def valid_slack_token!
    return if params.require(:token) == Rails.configuration
              .services['slack_token']
    render json: {
      text: I18n.t('.invalid_slack_token', scope: [:commands])
    }
  end

  def team_exists!
    @team = Team.find_by(external_id: params.require(:team_id))
    invalid_setup_response unless @team.present?
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
      response_type: :in_channel,
      text: I18n.t('.respond',
                   title: params[:text],
                   user_id: params.require(:user_id),
                   url: url,
                   scope: [:commands])
    }
  end

  def setup_channel!
    @channel = @team.channels.find_or_initialize_by(
      external_id: params.require(:channel_id)
    )
    @channel.name = params.require(:channel_name)
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

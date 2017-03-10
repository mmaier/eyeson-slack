# Executes slack command
class CommandsController < ApplicationController
  before_action :valid_slack_token!, only: [:create]
  before_action :team_exists!, only: [:create]
  before_action :setup_channel!, only: [:create]

  def create
    response = if 'help' == params[:text]
                 help_response
               else
                 meeting_response
               end

    respond_to_command_with(response)

    head :ok
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
      text: I18n.t('.respond',
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

  def respond_to_command_with(response)
    uri = URI.parse(params[:response_url])
    req = Net::HTTP::Post.new(uri)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    req['Content-Type'] = 'application/json'
    req.body = response.to_json
    http.request(req)
  end
end

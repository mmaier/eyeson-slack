# Executes slack command
class CommandsController < ApplicationController
  before_action :valid_slack_token!, only: [:create]
  before_action :team_exists!, only: [:create]
  before_action :user_belongs_to_team!, only: [:create]
  before_action :channel_belongs_to_team!, only: [:create]

  def create
    # Send immediate response to slack (must be <300ms)
    url = meeting_url(id: params.require(:channel_id))
    response = {
      response_type: :in_channel,
      text: I18n.t('.respond',
                   name: params.require(:user_name),
                   url: url,
                   scope: [:commands])
    }
    render json: response
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
    @team = Team.find_by(
      external_id: params.require(:team_id),
      ready: true
    )
    invalid_setup_response unless @team.present?
  end

  def user_belongs_to_team!
    @user = @team.users.find_or_initialize_by(
      external_id: params.require(:user_id)
    )
    @user.name = params.require(:user_name)
    @user.save!
  end

  def channel_belongs_to_team!
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

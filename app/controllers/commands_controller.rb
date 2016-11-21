# Executes slack command
class CommandsController < ApplicationController
  before_action :valid_slack_token!
  before_action :valid_team!
  before_action :valid_team_user_relation!
  before_action :valid_team_channel_relation!

  def respond
    # Send immediate response to slack (must be <200ms)
    url = meeting_url(id: @channel.external_id)
    response = {
      response_type: :in_channel,
      text: I18n.t('.respond', name: @user.name, url: url, scope: [:commands])
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

  def valid_team!
    @team = Team.find_by(
      external_id: params.require(:team_id)
    )
    return if @team.present?

    response = {
      text: I18n.t('.invalid_setup',
                   url: setup_url,
                   scope: [:commands])
    }
    render json: response
  end

  def valid_team_user_relation!
    @user = @team.users.find_or_initialize_by(
      external_id: params.require(:user_id)
    )
    @user.name = params.require(:user_name)
    @user.save!
  end

  def valid_team_channel_relation!
    @channel = @team.channels.find_or_initialize_by(
      external_id: params.require(:channel_id)
    )
    @channel.name = params.require(:channel_name)
    @channel.save!
  end
end

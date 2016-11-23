# Executes slack command
class CommandsController < ApplicationController
  before_action :slack_api, only: [:setup]

  before_action :valid_slack_token!, except: [:setup]
  before_action :valid_team!, except: [:setup]
  before_action :valid_team_user_relation!, except: [:setup]
  before_action :valid_team_channel_relation!, except: [:setup]

  def setup
    redirect_to @slack_api.authorize!(
      redirect_uri: oauth_url,
      scope:        'commands'
    )
  end

  def create
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
      external_id: params.require(:team_id),
      ready: true
    )
    invalid_setup_response unless @team.present?
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

  def invalid_setup_response
    response = {
      text: I18n.t('.invalid_setup',
                   url: setup_url,
                   scope: [:commands])
    }
    render json: response
  end
end

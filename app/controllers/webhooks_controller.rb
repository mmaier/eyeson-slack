# Webhook handling
class WebhooksController < ApplicationController
  before_action :valid_api_key!

  def create
    send(params[:type])
    head :ok
  end

  private

  def valid_api_key!
    @team = Team.find_by(api_key: params.require(:api_key))
    head :unauthorized unless @team.present?
  end

  def presentation_update
    # TODO: Upload slide to slack thread
  end

  def room_params
    params.require(:room)
  end
end

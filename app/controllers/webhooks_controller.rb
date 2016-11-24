# handle incoming webhooks from com-api
class WebhooksController < ApplicationController
  before_action :valid_types!
  before_action :team_exists!

  def create
    @team.ready = true if [true, 'true'].include?(params[:team][:ready])
    @team.api_key = params[:team][:api_key] if params[:team][:api_key].present?
    @team.save!
  end

  private

  def valid_types!
    return if params.require(:type) == 'team_changed'
    render json: {
      error: I18n.t('.invalid_type', scope: [:webhooks])
    }, status: :forbidden
  end

  def team_exists!
    @team = Team.find_by(api_key: params.require(:api_key))
    return if @team.present?
    render json: {
      error: I18n.t('.team_not_found', scope: [:webhooks])
    }, status: :not_found
  end
end

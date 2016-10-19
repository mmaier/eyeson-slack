class CommandsController < ApplicationController
	before_action :verify_slack_token

	def execute
		CommandJob.perform_later params.permit(:command, :user_id, :user_name, :channel_id, :channel_name, :response_url).to_h
		render :nothing => true, status: :ok
	end

	private

		def verify_slack_token
			unless params[:token] == APP_CONFIG['slack_token']
				render json: {error: "Verification token wrong"}, status: :forbidden
			end
		end
end

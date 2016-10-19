class CommandsController < ApplicationController
	before_action :verify_slack_token

	def execute
		CommandJob.perform_later params.to_h
		render json: {}, status: :ok
	end

	private

		def verify_slack_token
			unless params[:token] == APP_CONFIG['slack_token']
				render json: {error: "Verification token wrong"}, status: :forbidden
			end
		end
end

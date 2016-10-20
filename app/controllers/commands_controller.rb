class CommandsController < ApplicationController
	before_action :verify_slack_token

	def execute
		# Slash commands are restricted to be executed within 3000ms or via delayed response.
		# Dependent on multiple API requests, this can last longer, therefore we use delayed response.
		# https://api.slack.com/slash-commands#responding_to_a_command
		CommandJob.perform_later params.permit(:command, :user_id, :user_name, :channel_id, :channel_name, :response_url).to_h

		# Slack awaits immediate response with status 200, the text will be displayed to the initiator only
		render json: { text: "Give me a few seconds please..." }
	end

	private

		def verify_slack_token
			unless params[:token] == APP_CONFIG['slack_token']
				render json: { text: "Are you trying to hack us? Seems like the verification token was not correct..." }
			end
		end
end

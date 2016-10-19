class CommandsController < ApplicationController
	before_action :verify_slack_token

	def execute
		case params[:command]
		when "/eyeson"
			user = {
				id: params[:user_id],
				name: params[:user_name]
			}
			channel = {
				id: params[:channel_id],
				name: params[:channel_name]
			}
			render json: {meeting: MeetingManager.new(user, channel).create!}, status: :created
		else
			render json: {error: "Command not known"}, status: :method_not_allowed
		end
	end

	private

		def verify_slack_token
			unless params[:token] == SLACK_VERIFICATION_TOKEN
				render json: {error: "Verification token wrong"}, status: :forbidden
			end
		end
end

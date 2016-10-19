class CommandsController < ApplicationController
	before_action :verify_slack_token
	before_action :find_or_initialize_user

	def execute
		command = Command.new(params[:command]).execute(user: @user, params: params)
		render json: command.payload, status: command.status
	end

	private

		def verify_slack_token
			unless params[:token] == SLACK_VERIFICATION_TOKEN
				render json: {error: "Verification token wrong"}, status: :forbidden
			end
		end

		def find_or_initialize_user
			@user = User.new(id: params[:user_id], name: params[:user_name])
			unless @user.present?
				render json: {error: "User not found"}, status: :forbidden
			end
		end
end

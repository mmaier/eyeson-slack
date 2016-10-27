class MeetingsController < ApplicationController

	before_action :user_present

	def show
		#TODO: use a direct meeting access URL
		#TODO: check if user is allowed to join (= channel user)
		user = User.new(id: session[:user_id])
		redirect_to APP_CONFIG['eyeson_api'].split("/api/v2").first+'/'+params[:id]+'?join=true&access_token='+user.access_token
	end

	private

		def user_present
			unless session[:user_id].present?
				redirect_to login_path(redirect_uri: meeting_path(id: params[:id]))
			end
		end
end

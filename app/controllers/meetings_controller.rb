class MeetingsController < ApplicationController
	def show
		redirect_to login_path(redirect_uri: APP_CONFIG['eyeson_api'].split("/api/v2").first+'/'+params[:id])
	end
end

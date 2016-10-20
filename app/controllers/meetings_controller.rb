class MeetingsController < ApplicationController

	before_action :user_present

	def show
		meeting = Meeting.new(params[:id])
		meeting.add(session[:user_id])
		redirect_to meeting.url
	end

	private

		def user_present
			unless session[:user_id].present?
				redirect_to login_path(redirect_uri: meeting_path(id: params[:id]))
			end
		end
end

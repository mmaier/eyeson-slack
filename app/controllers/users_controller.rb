class UsersController < ApplicationController
	def login
		redirect_to params[:redirect_uri]
	end

	def oauth
	end

	def error
	end
end

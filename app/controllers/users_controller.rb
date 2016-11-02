class UsersController < ApplicationController

	before_action :oauth_client

	def login
		redirect_to @client.auth_code.authorize_url(redirect_uri: oauth_url(redirect_uri: params[:redirect_uri]), scope: 'identity.basic')
	end

	def oauth
		token = @client.auth_code.get_token(params[:code], redirect_uri: oauth_url(redirect_uri: params[:redirect_uri]))
		
		identity = JSON.parse(token.get('/api/users.identity?token='+token.token).body)
		#TODO: for more details:
		#profile = token.get('/api/users.profile.get?token='+token.token).response
		
		session[:user_id] = identity["user"]["id"]
		session[:user_name] = identity["user"]["name"]

		redirect_to params[:redirect_uri]
	end

	private

	def oauth_client
		@client = OAuth2::Client.new(APP_CONFIG['slack_key'], APP_CONFIG['slack_secret'], site: 'https://slack.com', authorize_url: '/oauth/authorize', token_url: '/api/oauth.access')
	end
	
end

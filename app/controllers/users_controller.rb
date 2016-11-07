# Authenticat users via oauth
class UsersController < ApplicationController
  before_action :oauth_client

  def login
    url = @client.auth_code.authorize_url(
      redirect_uri: oauth_url(redirect_uri: params[:redirect_uri])
    )
    redirect_to url, scope: 'identity.basic'
  end

  def oauth
    token = @client.auth_code.get_token(
      params[:code],
      redirect_uri: oauth_url(redirect_uri: params[:redirect_uri])
    )

    session[:access_token] = token.token

    redirect_to params[:redirect_uri]
  end
end

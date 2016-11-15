# Authenticat users via oauth
class UsersController < ApplicationController
  before_action :oauth_client

  def login
    url = @oauth.auth_code.authorize_url(
      redirect_uri: oauth_url(redirect_uri: params.require(:redirect_uri)),
      scope: 'identity.basic'
    )
    redirect_to url
  end

  def oauth
    token = @oauth.auth_code.get_token(
      params[:code],
      redirect_uri: oauth_url(redirect_uri: params.require(:redirect_uri))
    )

    redirect_to generate_uri(
      params.require(:redirect_uri),
      access_token: token.token
    )
  end

  private

  def generate_uri(uri, params)
    connector = (uri.include?('?') ? '&' : '?')
    query = params.map { |k, v| "#{k}=#{v}" }.join('&')
    uri + connector + query
  end
end

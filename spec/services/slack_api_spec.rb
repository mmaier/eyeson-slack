require 'rails_helper'

RSpec.describe SlackApi, type: :class do
  let(:slack_api) do
    SlackApi.new
  end
  # def oauth_token_success(redirect_uri: nil)
  #   @oauth_access = mock('Oauth token', token: 'abc')
  #   auth_code = mock('Auth code')
  #   auth_code.expects(:get_token)
  #            .with(
  #              'abc',
  #              redirect_uri: oauth_url(redirect_uri: redirect_uri)
  #            )
  #            .returns(@oauth_access)
  #   oauth = mock('Oauth')
  #   oauth.expects(:auth_code).returns(auth_code)
  #   OAuth2::Client.expects(:new).returns(oauth)
  # end
end

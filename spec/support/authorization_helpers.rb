
module AuthorizationHelpers
  def slack_user
    mock('Slack User', body: { user: { id: '123', name: 'Tester' } }.to_json)
  end

  def oauth_user
    token = mock('OAuth2::AccessToken', get: slack_user)
    OAuth2::AccessToken.expects(:from_kvform).returns(token)
  end
end

RSpec.configure do |config|
  config.include AuthorizationHelpers
end

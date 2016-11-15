
module AuthorizationHelpers
  def slack_user
    mock('Slack User', body: { user: { id: '123', name: 'Tester' } }.to_json)
  end

  def oauth_user_present
    token = mock('Oauth token', get: slack_user)
    OAuth2::AccessToken.expects(:from_kvform).returns(token)
  end

  def rest_response_with(res)
    req = mock('MCU Request')
    req.expects(:use_ssl=).at_least_once
    req.expects(:verify_mode=).at_least_once
    req.expects(:request).returns(res).at_least_once
    Net::HTTP.expects(:new).returns(req).at_least_once
  end
end

RSpec.configure do |config|
  config.include AuthorizationHelpers
end

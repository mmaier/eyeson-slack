
module AuthorizationHelpers
  def slack_models
    slack_models = mock('Slack User')
    slack_models.expects(:body).returns(
      {
        user: {
          id: '123',
          name: 'Tester'
        },
        profile: {
          image_48: '/avatar'
        },
        channel: {
          name: 'My Channel'
        }
      }.to_json
    ).at_least_once
    slack_models
  end

  def oauth_user_present
    token = mock('Oauth token')
    token.expects(:get).returns(slack_models).at_least_once
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

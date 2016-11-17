
module AuthorizationHelpers
  def slack_models
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
    }
  end

  def slack_response
    response = mock('Slack User')
    response.expects(:body).returns(
      slack_models.to_json
    ).at_least_once
    response
  end

  def oauth_user_present
    token = mock('Oauth token')
    token.expects(:get).returns(slack_response).at_least_once
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

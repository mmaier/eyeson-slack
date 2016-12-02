
module AuthorizationHelpers
  def slack_identity(user_id: '123', team_id: Faker::Code.isbn)
    {
      'url'     => 'https://eyeson-test.slack.com',
      'user'    => 'Tester',
      'user_id' => user_id,
      'team_id' => team_id
    }
  end

  def slack_profile
    {
      'profile' => {
        'first_name' => Faker::Internet.user_name,
        'last_name'  => Faker::Internet.user_name,
        'email'      => Faker::Internet.email,
        'image_48'   => 'avatar_url'
      }
    }
  end

  def authorized_as(user)
    session[user.team_id.to_s] = user.id.to_s
  end

  def expects_authorize_with(params)
    @slack_api = mock('Slack API')
    SlackApi.expects(:new).returns(@slack_api)
    @slack_api.expects(:authorize!).with(params)
              .returns('https://slack/auth_url')
  end

  def slack_api_authorized
    @slack_api = mock('Slack API')
    SlackApi.expects(:new).returns(@slack_api)
    @slack_api.expects(:authorized?).returns(true)
  end

  def rest_response_with(res)
    req = mock('Eyeson Request')
    req.expects(:use_ssl=).at_least_once
    req.expects(:verify_mode=).at_least_once
    req.expects(:request).returns(res).at_least_once
    Net::HTTP.expects(:new).returns(req).at_least_once
  end
end

RSpec.configure do |config|
  config.include AuthorizationHelpers
end


module AuthorizationHelpers
  def slack_auth(user_id: '123', team_id: Faker::Code.isbn)
    {
      'url'     => 'https://eyeson-test.slack.com',
      'user'    => 'Tester',
      'user_id' => user_id,
      'team'    => Faker::Team.name,
      'team_id' => team_id
    }
  end

  def slack_identity(user_id: '123', email: Faker::Internet.email, team_id: Faker::Code.isbn)
    {
      'user' => {
        'id'       => user_id,
        'email'    => email,
        'name'     => Faker::Internet.user_name,
        'image_48' => 'avatar_url'
      },
      'team' => {
        'id'       => team_id
      }
    }
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
end

RSpec.configure do |config|
  config.include AuthorizationHelpers
end

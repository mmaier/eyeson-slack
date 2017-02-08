
module ApiHelpers
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

  def expects_slack_api_authorized
    @slack_api = mock('Slack API')
    SlackApi.expects(:new).returns(@slack_api)
    @slack_api.expects(:authorized?).returns(true)
  end

  def expects_slack_request_with(access_token)
    @slack_api = mock('Slack API')
    SlackApi.expects(:new).with(access_token).returns(@slack_api)
    @slack_api.expects(:request).once
  end

  def expects_eyeson_room_with(url = Faker::Internet.url)
    url_response = mock('Room URL')
    url_response.expects(:url).returns(url).at_most_once
    Eyeson::Room.expects(:new)
                .returns(url_response)
  end
end

RSpec.configure do |config|
  config.include ApiHelpers
end

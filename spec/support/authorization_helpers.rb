
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

  def slack_identity(user_id: '123', team_id: Faker::Code.isbn)
    {
      'user' => {
        'id'       => user_id,
        'email'    => Faker::Internet.email,
        'name'     => Faker::Internet.user_name,
        'image_48' => 'avatar_url'
      },
      'team' => {
        'id'       => team_id
      }
    }
  end

  def slack_info(user_id: '123')
    {
      'user' => {
        'id'       => user_id,
        'name'     => Faker::Internet.user_name,
        'profile'  => {
          'email'     => Faker::Internet.email,
          'real_name' => Faker::Internet.user_name,
          'image_48'  => 'avatar_url'
        }
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

  def api_response_with(res)
    req = mock('Eyeson Request')
    req.expects(:use_ssl=).at_least_once
    req.expects(:verify_mode=).at_least_once
    req.expects(:request).returns(res).at_least_once
    Net::HTTP.expects(:new).returns(req).at_least_once
  end

  def uses_internal_api
    config = Rails.configuration.services
    auth = {
      'username' => 'user',
      'password' => 'pwd'
    }
    expect(config['internal_pwd']).to be_present
    File.expects(:read)
    YAML.expects(:load)
        .returns(auth)
    req = mock('REST Request')
    req.expects(:basic_auth).with(auth['username'], auth['password'])
    req.expects(:[]=).once
    req.expects(:body=).once
    Net::HTTP::Post.expects(:new).returns(req)
  end
end

RSpec.configure do |config|
  config.include AuthorizationHelpers
end

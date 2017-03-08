require 'rails_helper'

RSpec.describe Team, type: :model do
  it { is_expected.to have_many :users }
  it { is_expected.to have_many :channels }

  it { is_expected.to have_fields(:api_key, :external_id).of_type(String) }
  it { is_expected.to have_fields(:url).of_type(String) }
  it { is_expected.to have_index_for(external_id: 1) }

  it { is_expected.to validate_presence_of(:api_key) }
  it { is_expected.to validate_presence_of(:url) }
  it { is_expected.to validate_presence_of(:external_id) }
  it { is_expected.to validate_uniqueness_of(:external_id) }
  it { is_expected.to validate_presence_of(:name) }

  it 'should setup a new team' do
    external_id = Faker::Code.isbn
    api_key = Faker::Crypto.md5

    key = mock('API Key', key: api_key, webhooks: mock('Webhooks', create!: nil))
    Eyeson::ApiKey.expects(:create!).returns(key)
    team = Team.setup!(
      external_id: external_id,
      email: Faker::Internet.email,
      url:   Faker::Internet.url,
      name:  Faker::Team.name
    )

    expect(team.external_id).to eq(external_id)
    expect(team.api_key).to eq(api_key)
  end

  it 'should create webhooks after setup' do
    team     = create(:team)
    key      = mock('API Key')
    webhooks = mock('API Webhooks')
    key.expects(:webhooks).returns(webhooks)
    webhooks.expects(:create!)
            .with({
              url: Rails.application.routes.url_helpers.webhooks_url,
              types: %w(presentation_update)
            })
    team.add_webhook(key)
  end

  it 'should return existing team on setup' do
    team = create(:team)
    Eyeson::ApiKey.expects(:create!).never
    Team.setup!(
      external_id: team.external_id,
      email: Faker::Internet.email,
      url: Faker::Internet.url
    )
  end

  it 'should add a user to team' do
    team = create(:team)
    identity = slack_identity
    team.add!(
      access_token: Faker::Crypto.md5,
      scope: 'identity.basic',
      identity:     identity
    )
    expect(User.find_by(
             team_id: team.id,
             external_id: identity['user']['id']
    )).to be_present
  end

  it 'should use name, email and company for api key registration' do
    name = Faker::Team.name
    email = Faker::Internet.email
    url = 'https://teamname.slack.com'
    api = mock('API Key', key: '123', webhooks: mock('Webhooks', create!: nil))
    Eyeson::ApiKey.expects(:create!)
          .with(name: name, email: email, company: 'Slack')
          .returns(api)
    Team.setup!(
      external_id: Faker::Code.isbn,
      email: email,
      name: name,
      url: url
    )
  end
end

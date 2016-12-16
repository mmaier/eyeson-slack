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

  it 'should setup a new team' do
    external_id = Faker::Code.isbn
    api_key = Faker::Crypto.md5

    key = mock('API Key', key: api_key)
    ApiKey.expects(:new).returns(key)
    team = Team.setup!(
      external_id: external_id,
      email: Faker::Internet.email,
      url: Faker::Internet.url
    )

    expect(team.external_id).to eq(external_id)
    expect(team.api_key).to eq(api_key)
  end

  it 'should return existing team on setup' do
    team = create(:team)
    ApiKey.expects(:new).never
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
end

require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) do
    create(:user)
  end

  it { is_expected.to belong_to :team }

  it { is_expected.to have_fields(:external_id).of_type(String) }
  it { is_expected.to have_fields(:access_token).of_type(String) }
  it { is_expected.to have_fields(:scope).of_type(Array) }
  it { is_expected.to have_fields(:avatar, :name).of_type(String) }
  it { is_expected.to have_index_for(team_id: 1, external_id: 1) }

  it { is_expected.to validate_presence_of(:external_id) }
  it { is_expected.to validate_uniqueness_of(:external_id) }
  it { is_expected.to validate_presence_of(:access_token) }
  it { is_expected.to validate_presence_of(:scope) }
  it { is_expected.to validate_presence_of(:name) }

  it 'provides a scope check' do
    expect(user.scope_required!([user.scope.first])).to be_nil
  end

  it 'raises SlackApi::MissingScope unless required scope is present' do
    expect { user.scope_required!(['required_scope']) }
      .to raise_error(SlackApi::MissingScope)
  end

  it 'should have an ip address attr_accessor' do
    ip = Faker::Internet.ip_v4_address
    user.ip_address = ip
    expect(user.ip_address).to eq(ip)
  end
end

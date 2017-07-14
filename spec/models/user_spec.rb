require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) do
    create(:user)
  end

  it { is_expected.to belong_to :team }

  it { is_expected.to have_fields(:external_id).of_type(String) }
  it { is_expected.to have_fields(:access_token).of_type(String) }
  it { is_expected.to have_fields(:scope).of_type(Array) }
  it { is_expected.to have_fields(:avatar, :name, :email).of_type(String) }
  it { is_expected.to have_index_for(external_id: 1)}
  it { is_expected.to have_index_for(team_id: 1, external_id: 1).with_options(unique: true) }
  it { is_expected.to have_index_for(team_id: 1, email: 1) }

  it { is_expected.to validate_presence_of(:external_id) }
  it { is_expected.to validate_uniqueness_of(:external_id) }
  it { is_expected.to validate_presence_of(:access_token) }
  it { is_expected.to validate_presence_of(:scope) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:email) }

  it 'should provide a scope check' do
    expect(user.scope_required!([user.scope.first])).to be_nil
  end

  it 'should raise SlackApi::MissingScope unless required scope is present' do
    expect { user.scope_required!(['required_scope']) }
      .to raise_error(SlackApi::MissingScope)
  end

  it 'should return a mapped user for api interaction' do
    expect(user.mapped).to eq({
      id:     user.email,
      email:  user.email,
      name:   user.name,
      avatar: user.avatar
    })
  end
end

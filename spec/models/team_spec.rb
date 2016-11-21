require 'rails_helper'

RSpec.describe Team, type: :model do
  let(:team) do
    create(:team)
  end

  it { is_expected.to have_many :users }
  it { is_expected.to have_many :channels }

  it { is_expected.to have_fields(:api_key, :external_id).of_type(String) }
  it { is_expected.to have_fields(:confirm_url).of_type(String) }
  it { is_expected.to have_fields(:confirmed).of_type(Mongoid::Boolean) }
  it { is_expected.to have_index_for(external_id: 1) }

  it { is_expected.to validate_presence_of(:api_key) }
  it { is_expected.to validate_presence_of(:external_id) }
  it { is_expected.to validate_uniqueness_of(:external_id) }
end
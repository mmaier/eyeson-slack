require 'rails_helper'

RSpec.describe User, type: :model do
  it { is_expected.to belong_to :team }

  it { is_expected.to have_fields(:external_id).of_type(String) }
  it { is_expected.to have_fields(:access_token).of_type(String) }
  it { is_expected.to have_fields(:avatar, :name).of_type(String) }
  it { is_expected.to have_index_for(team_id: 1, external_id: 1) }

  it { is_expected.to validate_presence_of(:external_id) }
  it { is_expected.to validate_uniqueness_of(:external_id) }
  it { is_expected.to validate_presence_of(:access_token) }
  it { is_expected.to validate_presence_of(:name) }
end

require 'rails_helper'

RSpec.describe Channel, type: :model do
  it { is_expected.to belong_to :team }

  it { is_expected.to have_fields(:external_id, :name, :thread_id).of_type(String) }
  it { is_expected.to have_fields(:access_key).of_type(String) }
  it { is_expected.to have_fields(:users_mentioned).of_type(Array) }
  it { is_expected.to have_fields(:new_command).of_type(Mongoid::Boolean) }
  it { is_expected.to have_index_for(external_id: 1).with_options(unique: true) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:new_command) }
  it { is_expected.to validate_presence_of(:external_id) }
  it { is_expected.to validate_uniqueness_of(:external_id) }
end

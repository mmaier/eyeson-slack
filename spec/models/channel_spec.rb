require 'rails_helper'

RSpec.describe Channel, type: :model do
  it { is_expected.to belong_to :team }

  it { is_expected.to have_fields(:external_id, :name, :thread_id).of_type(String) }
  it { is_expected.to have_fields(:access_key).of_type(String) }
  it { is_expected.to have_fields(:initializer_id).of_type(BSON::ObjectId) }
  it { is_expected.to have_fields(:last_question_queued).of_type(Float) }
  it { is_expected.to have_fields(:broadcasting).of_type(Mongoid::Boolean) }
  it { is_expected.to have_fields(:next_question_displayed_at).of_type(DateTime) }
  it { is_expected.to have_fields(:webinar_mode).of_type(Mongoid::Boolean) }
  it { is_expected.to have_index_for(external_id: 1).with_options(unique: true) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:external_id) }
  it { is_expected.to validate_presence_of(:webinar_mode) }
  
  it { is_expected.to validate_uniqueness_of(:external_id) }
end

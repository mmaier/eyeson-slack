FactoryGirl.define do
  factory :channel do
    team { create(:team) }
    external_id { Faker::Code.isbn }
    name { Faker::Team.name }
  end
end

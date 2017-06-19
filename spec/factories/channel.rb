FactoryGirl.define do
  factory :channel do
    team           { create(:team) }
    external_id    { Faker::Code.isbn }
    name           { Faker::Team.name }
    initializer_id { create(:user, team: team).id }
  end
end

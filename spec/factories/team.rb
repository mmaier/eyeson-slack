FactoryGirl.define do
  factory :team do
    external_id { Faker::Code.isbn }
    url         { Faker::Internet.url }
    name        { Faker::Team.name }
  end
end

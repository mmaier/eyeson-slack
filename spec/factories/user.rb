FactoryGirl.define do
  factory :user do
    team { create(:team) }
    external_id { Faker::Code.isbn }
    name { Faker::Internet.user_name }
    avatar { Faker::Internet.url }
  end
end

FactoryGirl.define do
  factory :user do
    team { create(:team) }
    external_id { Faker::Code.isbn }
    access_token { Faker::Crypto.md5 }
    email { Faker::Internet.email }
    name { Faker::Internet.user_name }
    avatar { Faker::Internet.url }
  end
end

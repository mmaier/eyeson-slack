FactoryGirl.define do
  factory :team do
    external_id { Faker::Internet.email }
    url         { Faker::Internet.url }
    api_key     { Faker::Crypto.md5 }
    name        { Faker::Team.name }
  end
end

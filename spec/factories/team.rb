FactoryGirl.define do
  factory :team do
    external_id { Faker::Code.isbn }
    url { Faker::Internet.url }
    api_key { Faker::Crypto.md5 }
  end
end

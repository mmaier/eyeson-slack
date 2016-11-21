FactoryGirl.define do
  factory :team do
    external_id { Faker::Code.isbn }
    api_key { Faker::Crypto.md5 }
    confirmed { true }
    confirm_url { Faker::Internet.url }
  end
end

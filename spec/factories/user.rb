FactoryGirl.define do
  factory :user do
    team { create(:team) }
    external_id { Faker::Code.isbn }
    access_token { Faker::Crypto.md5 }
    scope { %w(identity.basic identity.avatar chat:write:user) }
    name { Faker::Internet.user_name }
    avatar { Faker::Internet.url }
  end
end

FactoryGirl.define do
  factory :user do
    team         { create(:team) }
    external_id  { Faker::Code.isbn }
    access_token { Faker::Crypto.md5 }
    scope        { %w(identity.basic identity.avatar chat:write:user files:write:user) }
    name         { Faker::Internet.user_name }
    email        { Faker::Internet.email }
    avatar       { Faker::Internet.url }
    confirmed    { true }
  end
end

FactoryBot.define do
  factory :author do
    email { Faker::Internet.unique.email }
    password { "password123" }
  end
end

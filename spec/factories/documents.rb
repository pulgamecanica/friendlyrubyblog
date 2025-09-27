FactoryBot.define do
  factory :document do
    association :author
    association :series, factory: :series
    kind { "post" }
    title { "My Post" }
    description { "Hello" }
    published { true }
    published_at { Time.current }
  end
end

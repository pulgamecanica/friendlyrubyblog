FactoryBot.define do
  factory :page_view do
    association :document
    visited_at { Time.current }
    unique_visitor_id { SecureRandom.uuid }
    country { "United States" }
    device { "Desktop" }
    browser { "Chrome" }
  end
end

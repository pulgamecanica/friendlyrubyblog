FactoryBot.define do
  factory :comment do
    association :commentable, factory: :document
    body_markdown { "Nice!" }
    status { "visible" }
    actor_hash { "actor123" }
  end
end

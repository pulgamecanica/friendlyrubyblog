FactoryBot.define do
  factory :like do
    association :likable, factory: :document
    actor_hash { "actor123" }
  end
end

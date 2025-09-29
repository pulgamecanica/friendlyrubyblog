FactoryBot.define do
  factory :tag do
    sequence(:title) { |n| "Tag #{n}" }
    sequence(:slug)  { |n| "tag-#{n}" }
    color { "#%06x" % (rand * 0xffffff) }
  end
end

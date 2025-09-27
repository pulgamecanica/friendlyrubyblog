FactoryBot.define do
  factory :markdown_block do
    association :document
    type { "MarkdownBlock" }
    position { 1 }
    data { { "markdown" => "# Hi" } }
  end

  factory :code_block do
    association :document
    type { "CodeBlock" }
    position { 2 }
    data { { "language" => "ruby", "code" => "puts 1" } }
  end
end

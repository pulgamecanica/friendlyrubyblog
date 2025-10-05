# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create series
Series.uncategorized!

# Create or find author
author = Author.find_or_create_by!(email: "author@author.com") do |a|
  a.password = "author123"
  a.password_confirmation = "author123"
end

puts "✓ Author created/found: #{author.email}"

# Create dummy posts with fake views
puts "\nCreating dummy posts with views..."

series = [
  Series.find_or_create_by!(title: "Ruby Tutorials", slug: "ruby-tutorials") { |s| s.description = "Learn Ruby programming" },
  Series.find_or_create_by!(title: "Web Development", slug: "web-development") { |s| s.description = "Full-stack web development guides" },
  Series.find_or_create_by!(title: "DevOps", slug: "devops") { |s| s.description = "DevOps and deployment guides" }
]

tags = []
%w[ruby rails javascript tutorial beginner advanced backend frontend devops].each do |tag_name|
  tags << Tag.find_or_create_by!(title: tag_name)
end

# Create 20 posts with varying data
20.times do |i|
  created_date = Faker::Date.between(from: 90.days.ago, to: Date.today)

  doc = Document.create!(
    author: author,
    title: Faker::Hacker.say_something_smart.titleize,
    description: Faker::Lorem.paragraph(sentence_count: 2),
    kind: %w[post note page].sample,
    series: series.sample,
    published: [ true, true, true, false ].sample, # 75% published
    created_at: created_date,
    updated_at: created_date + rand(0..7).days
  )

  # Add random tags
  doc.tags << tags.sample(rand(1..4))

  # Add some blocks
  rand(2..5).times do |block_idx|
    MarkdownBlock.create!(
      document: doc,
      position: block_idx + 1,
      data: { "markdown" => Faker::Lorem.paragraphs(number: rand(2..4)).join("\n\n") }
    )
  end

  # Generate page views with realistic patterns
  if doc.published?
    # Views spread over time since creation
    view_count = rand(10..500)
    unique_visitors = rand(5..100)

    # Generate unique visitor IDs
    visitor_ids = unique_visitors.times.map { SecureRandom.uuid }

    view_count.times do
      visit_date = Faker::Date.between(from: doc.created_at, to: Date.today)

      PageView.create!(
        document: doc,
        visited_at: visit_date + rand(0..23).hours + rand(0..59).minutes,
        unique_visitor_id: visitor_ids.sample,
        ip_address: Faker::Internet.ip_v4_address,
        user_agent: Faker::Internet.user_agent,
        device: %w[desktop mobile tablet].sample,
        browser: %w[Chrome Firefox Safari Edge].sample,
        country: Faker::Address.country_code
      )
    end

    puts "  ✓ Created: '#{doc.title}' (#{view_count} views from #{unique_visitors} visitors)"
  else
    puts "  ✓ Created: '#{doc.title}' (draft)"
  end
end

puts "\n✓ Created 20 dummy posts with realistic view data\n\n"

# Create interactive languages
languages = [
  { name: 'Ruby', extension: 'rb', executable_command: 'ruby', interactive: true },
  { name: 'JavaScript', extension: 'js', executable_command: 'node', interactive: true },
  { name: 'TypeScript', extension: 'ts', executable_command: 'tsx', interactive: true },
  { name: 'Python', extension: 'py', executable_command: 'python3', interactive: true },
  { name: 'Bash', extension: 'sh', executable_command: 'bash', interactive: true },

  # C Standards
  { name: 'C (C98)', extension: 'c', executable_command: 'gcc_c98_wrapper', interactive: true },
  { name: 'C (GNU11)', extension: 'c', executable_command: 'gcc_gnu11_wrapper', interactive: true },

  # C++ Standards
  { name: 'C++ (C++98)', extension: 'cpp', executable_command: 'g++_98_wrapper', interactive: true },
  { name: 'C++ (C++11)', extension: 'cpp', executable_command: 'g++_11_wrapper', interactive: true },
  { name: 'C++ (C++17)', extension: 'cpp', executable_command: 'g++_17_wrapper', interactive: true }
]

languages.each do |lang_attrs|
  existing_language = Language.find_by(name: lang_attrs[:name])

  if existing_language
    # Update existing language if needed
    existing_language.update!(
      extension: lang_attrs[:extension],
      executable_command: lang_attrs[:executable_command],
      interactive: lang_attrs[:interactive]
    )
  else
    # Create new language
    Language.create!(lang_attrs)
  end
end

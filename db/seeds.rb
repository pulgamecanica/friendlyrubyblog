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

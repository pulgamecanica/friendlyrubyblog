# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"

Rails.application.load_tasks

task :lsphere do
  sh 'lsphere -o app/assets/images --svg --ignore "node_modules .* tmp" && rm app/assets/images/circle.html && rm  app/assets/images/circle.json'
end

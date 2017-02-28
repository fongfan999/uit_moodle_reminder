namespace :users do
  task get_courses: :environment do
    User.get_courses
  end
end
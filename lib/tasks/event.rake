namespace :events do
  desc 'Refesh remote events'

  task refresh: :environment do    
    # Existing users
    User.fetch_new_events
  end
end
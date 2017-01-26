namespace :events do
  desc 'Refesh remote events'

  task refresh: :environment do    
    # Existing users
    User.fetch_new_events!
    # Sending email
    Event.today.each do |event|
      UserMailer.upcoming_events(event)
    end
  end
end
namespace :events do
  task refresh: :environment do
    User.fetch_new_events
  end

  task clean: :environment do
    Event.clean
  end
end
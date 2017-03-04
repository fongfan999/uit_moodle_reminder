namespace :notifications do
  task refresh: :environment do
    Notification.fetch_new_notifications
  end

  task clean: :environment do
    Notification.clean
  end
end
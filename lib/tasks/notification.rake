namespace :notifications do
  task refresh: :environment do
    Notification.fetch_new_notifications
  end
end
# Preview all emails at http://localhost:3000/rails/mailers/event_notifier_mailer
class EventNotifierMailerPreview < ActionMailer::Preview
  def upcoming
    EventNotifierMailer.upcoming(User.first)
  end
end

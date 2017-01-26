# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
  def subscribe_confirmation
    UserMailer.subscribe_confirmation(User.first)
  end

  def upcoming_event
    UserMailer.upcoming_event(User.first, Event.first)
  end
end

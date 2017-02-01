# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
  def subscribe_confirmation
    UserMailer.subscribe_confirmation(User.first)
  end

  def unsubscribe_confirmation
    UserMailer.unsubscribe_confirmation(User.first)
  end

  def upcoming_event
    UserMailer.upcoming_event(User.first, Event.first, User.milestone_to_time_left(1.day))
  end

  def cannot_login
    UserMailer.cannot_login(User.first)
  end
end

class EventNotifierMailer < ApplicationMailer
  def upcoming(user)
    @user = user
    mail to: user.email, subject: "Hello World"
  end
end

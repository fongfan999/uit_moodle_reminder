class UserMailer < ApplicationMailer
  def subscribe_confirmation(user)
    @user = user
    mail to: user.email, subject: "Đăng ký nhận thông báo từ Moodle thành công"
  end

  def upcoming_event(user, event)
    @user = user
    @event = event
    # emails = @event.users.collect(&:email).join(",")
    mail to: @user.email,
      subject: "Bạn đang có 1 deadline sắp hết hạn - [30 phút]"
  end
end

class UserMailer < ApplicationMailer
  def subscribe_confirmation(user)
    @user = user

    mail to: user.email, subject: "Đăng ký nhận thông báo từ Moodle thành công"
  end

  def unsubscribe_confirmation(user)
    @user = user
      render text: "Bạn đã ngừng đăng ký nhận thông báo thành công."
    mail to: user.email,
      subject: "Bạn đã ngừng đăng ký nhận thông báo thành công"
  end

  def upcoming_event(user, event, time_left)
    @user = user
    @event = event
    @time_left = time_left

    mail to: @user.email,
      subject: "Bạn đang có 1 deadline sắp hết hạn - [#{@time_left}]"
  end

  def cannot_login(user)
    @user = user

    mail to: @user.email, subject: "Xin hãy cập nhật lại mật khẩu"
  end
end

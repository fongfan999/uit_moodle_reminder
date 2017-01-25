class UserMailer < ApplicationMailer
  def subscribe_confirmation(user)
    @user = user
    mail to: user.email, subject: "Đăng ký nhận thông báo từ Moodle thành công"
  end
end

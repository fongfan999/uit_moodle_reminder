class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def subscribe
    @user = User.find_by_username_or_initialize_by(user_params)

    if @user.persisted?
      @flash = "existing-failure"
    else
      if @user.is_authenticated? && @user.save(validate: false)
        @flash = "success"
        UserMailer.subscribe_confirmation(@user).deliver_later
      else
        @flash = "failure"
      end
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  def unsubscribe
    if user = User.find_by_token(params[:token])
      # Backup data
      Student.create(user.attributes.slice("name", "username", "password"))

      UserMailer.unsubscribe_confirmation(user).deliver_later
      user.unsubscribe

      render plain: "Bạn đã ngừng đăng ký nhận tất cả thông báo thành công."
    else
      redirect_to root_path
    end
  end

  def unsubscribe_event
    event = Event.find_by_id(params[:event])
    user = User.find_by_token(params[:token])

    if event && user
      user.unsubscribe_event(event)
      render plain: "Bạn đã ngừng đăng ký nhận thông báo: #{event.referer}"
    else
      redirect_to root_path
    end
  end

  private

  def user_params
    params.require(:user).permit(:username, :password)
  end
end

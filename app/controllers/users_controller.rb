class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def subscribe
    @user = User.find_by_username_or_initialize_by(user_params)

    if @user.persisted?
      # flash.now[:alert] = "Account is existed in system"
      @flash = "existing-failure"
      @user = User.new
      # render "new"
    else
      if @user.is_authenticated? && @user.save(validate: false)
        # flash[:notice] = "Success"
        @flash = "success"
        UserMailer.subscribe_confirmation(@user).deliver_later
        # redirect_to thankyou_path
      else
        # flash.now[:alert] = "Failed"
        @flash = "failure"
        # render "new"
      end
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  def unsubscribe
    if user = User.find_by_token(params[:token])
      Student.create(user.attributes.slice("name", "username", "password"))
      user.destroy
      render text: "Bạn đã ngừng đăng ký nhận thông báo thành công."
    else
      redirect_to root_path
    end
  end

  private

  def user_params
    params.require(:user).permit(:username, :password)
  end
end

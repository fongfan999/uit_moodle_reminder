class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def subscribe
    @user = User.new(user_params)

    # if @user.save
      flash[:notice] = "Success"
      EventNotifierMailer.upcoming(@user).deliver_now
      redirect_to root_path
    # else
    #   flash.now[:alert] = "Failed"
    #   render "new"
    # end
  end

  private

  def user_params
    params.require(:user).permit(:username, :password)
  end
end

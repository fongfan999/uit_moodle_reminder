class User < ApplicationRecord
  validates :email, presence: true
  validates :password, presence: true
  
  def email
    username + '@gm.uit.edu.vn'
  end
end

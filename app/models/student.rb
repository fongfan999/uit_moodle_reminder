class Student < ApplicationRecord
  validates :username, uniqueness: true
end

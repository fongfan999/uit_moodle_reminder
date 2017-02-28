class Course < ApplicationRecord
  has_and_belongs_to_many :users

  def self.belongs_to(notification)
    Course.find_by_id(
      Course.pluck(:id, :name)
        .find { |c| notification.title =~ /\(#{c[1]}\)/ }.try(:first)
    )
  end
end

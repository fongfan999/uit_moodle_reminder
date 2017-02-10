class Event < ApplicationRecord
  has_many :reminders
  has_many :users, through: :reminders

  scope :clean, -> { where("date < ?", Time.zone.now).delete_all }

  def self.find_without_by_date_or_initialize_by(params)
    where(params.except(:date)).first_or_initialize(params)
  end
end

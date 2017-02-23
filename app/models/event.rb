class Event < ApplicationRecord
  has_many :reminders
  has_many :users, through: :reminders

  scope :clean, -> { where("date < ?", Time.zone.now).delete_all }

  def self.find_by_link_or_initialize_by(params)
    where(params.slice(:link)).first_or_initialize(params)
  end
end

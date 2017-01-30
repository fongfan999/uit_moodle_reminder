class CreateReminders < ActiveRecord::Migration[5.0]
  def change
    create_table :reminders do |t|
      t.references :event, foreign_key: true
      t.references :user, foreign_key: true
    end
  end
end

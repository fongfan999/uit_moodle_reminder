class AddMessengerToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :messenger, :boolean, default: false
  end
end

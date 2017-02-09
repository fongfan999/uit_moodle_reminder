class AddSenderIdToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :sender_id, :string
    add_index :users, :sender_id
  end
end

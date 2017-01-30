class DropJoinTableEventsUsers < ActiveRecord::Migration[5.0]
  def change
    drop_join_table :events, :users
  end
end

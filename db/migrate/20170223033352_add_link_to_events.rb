class AddLinkToEvents < ActiveRecord::Migration[5.0]
  def change
    add_column :events, :link, :string
    add_index :events, :link
  end
end

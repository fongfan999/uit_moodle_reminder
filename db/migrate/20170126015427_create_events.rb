class CreateEvents < ActiveRecord::Migration[5.0]
  def change
    create_table :events do |t|
      t.string :referer
      t.string :course
      t.datetime :date
      t.text :description

      t.timestamps
    end
  end
end

class CreateStudents < ActiveRecord::Migration[5.0]
  def change
    create_table :students do |t|
      t.string :name
      t.string :username
      t.string :password

      t.timestamps
    end
  end
end

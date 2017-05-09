class DropTableCoursesAndNotifications < ActiveRecord::Migration[5.0]
  def up
    drop_table :courses_users
    drop_table :courses
    drop_table :notifications
  end

  def down 
    create_table :notifications do |t|
      t.string :title
      t.text :content
      t.string :link

      t.timestamps
    end

    create_table :courses do |t|
      t.string :name

      t.timestamps
    end

    create_join_table :courses, :users do |t|
      t.index [:course_id, :user_id]
      t.index [:user_id, :course_id]
    end
  end
end

class CreateAttendances < ActiveRecord::Migration[5.1]
  def change
    create_table :attendances do |t|
      t.integer :course_id
      t.string :andrew_id
      t.timestamp :date
      t.string :attendance_type

      t.timestamps
    end
  end
end

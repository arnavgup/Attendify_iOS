class CreateEnrollments < ActiveRecord::Migration[5.1]
  def change
    create_table :enrollments do |t|
      t.integer :course_id
      t.string :andrew_id
      t.boolean :active

      t.timestamps
    end
  end
end

class CreateCourses < ActiveRecord::Migration[5.1]
  def change
    create_table :courses do |t|
      t.integer :professor_id
      t.string :class_number
      t.string :semester_year
      t.boolean :active

      t.timestamps
    end
  end
end

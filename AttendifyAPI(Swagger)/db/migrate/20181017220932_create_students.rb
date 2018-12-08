class CreateStudents < ActiveRecord::Migration[5.1]
  def change
    create_table :students do |t|
      t.string :andrew_id
      t.string :first_name
      t.string :last_name
      t.boolean :active

      t.timestamps
    end
  end
end

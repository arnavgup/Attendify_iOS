class CreatePhotos < ActiveRecord::Migration[5.1]
  def change
    create_table :photos do |t|
      t.string :andrew_id
      t.string :photo_url

      t.timestamps
    end
  end
end

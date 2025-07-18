class CreateGenres < ActiveRecord::Migration[8.0]
  def change
    create_table :genres do |t|
      t.string :genre_id, null: false, index: { unique: true }
      t.string :name

      t.timestamps
    end
  end
end

class CreateMovies < ActiveRecord::Migration[8.0]
  def change
    create_table :movies do |t|
      t.string :movie_id, null: false, index: { unique: true }
      t.string :title
      t.text :description

      t.timestamps
    end
  end
end

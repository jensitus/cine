class CreateMoviesGenres < ActiveRecord::Migration[8.0]
  def change
    create_table :movies_genres do |t|
      t.belongs_to :genre
      t.belongs_to :movie
      t.index [:movie_id, :genre_id], unique: true
    end
  end
end

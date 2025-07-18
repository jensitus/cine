class AddIndexToGenreMovies < ActiveRecord::Migration[8.0]
  def change
    add_index :genres_movies, [:movie_id, :genre_id], unique: true
  end
end

class AddColumnsToMovies < ActiveRecord::Migration[8.0]
  def change
    add_column :movies, :year, :string
    add_column :movies, :countries, :string
    add_column :movies, :poster_path, :string
    add_column :movies, :actors, :string
    add_column :movies, :director, :string
  end
end

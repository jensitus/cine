class AddTmdbIdToMovie < ActiveRecord::Migration[8.0]
  def change
    add_column :movies, :tmdb_id, :integer
  end
end

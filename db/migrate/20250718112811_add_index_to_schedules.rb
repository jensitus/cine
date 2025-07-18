class AddIndexToSchedules < ActiveRecord::Migration[8.0]
  def change
    add_index :schedules, [:time, :movie_id, :cinema_id], unique: true
  end
end

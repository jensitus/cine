class AddIndexToSchedulesTags < ActiveRecord::Migration[8.0]
  def change
    add_index :schedules_tags, [:tag_id, :schedule_id], unique: true
  end
end

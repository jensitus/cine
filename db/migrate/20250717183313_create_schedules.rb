class CreateSchedules < ActiveRecord::Migration[8.0]
  def change
    create_table :schedules do |t|
      t.datetime :time
      t.boolean :three_d
      t.boolean :ov
      t.string :info
      t.belongs_to :movie
      t.belongs_to :cinema

      t.timestamps
    end
  end
end

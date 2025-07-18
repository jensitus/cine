class CreateCinemas < ActiveRecord::Migration[8.0]
  def change
    create_table :cinemas do |t|
      t.string :cinema_id, null: false, index: { unique: true }
      t.string :title
      t.string :county
      t.string :uri

      t.timestamps
    end
  end
end

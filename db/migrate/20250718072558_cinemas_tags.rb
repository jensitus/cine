class CinemasTags < ActiveRecord::Migration[8.0]
  def change
    create_table :cinemas_tags do |t|
      t.belongs_to :cinema
      t.belongs_to :tag
      t.index [:cinema_id, :tag_id], unique: true
    end
  end
end

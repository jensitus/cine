# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_18_122854) do
  create_table "cinemas", force: :cascade do |t|
    t.string "cinema_id", null: false
    t.string "title"
    t.string "county"
    t.string "uri"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cinema_id"], name: "index_cinemas_on_cinema_id", unique: true
  end

  create_table "cinemas_tags", force: :cascade do |t|
    t.integer "cinema_id"
    t.integer "tag_id"
    t.index ["cinema_id", "tag_id"], name: "index_cinemas_tags_on_cinema_id_and_tag_id", unique: true
    t.index ["cinema_id"], name: "index_cinemas_tags_on_cinema_id"
    t.index ["tag_id"], name: "index_cinemas_tags_on_tag_id"
  end

  create_table "genres", force: :cascade do |t|
    t.string "genre_id", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["genre_id"], name: "index_genres_on_genre_id", unique: true
  end

  create_table "genres_movies", id: false, force: :cascade do |t|
    t.integer "movie_id", null: false
    t.integer "genre_id", null: false
    t.index ["movie_id", "genre_id"], name: "index_genres_movies_on_movie_id_and_genre_id", unique: true
  end

  create_table "movies", force: :cascade do |t|
    t.string "movie_id", null: false
    t.string "title"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["movie_id"], name: "index_movies_on_movie_id", unique: true
  end

  create_table "movies_genres", force: :cascade do |t|
    t.integer "genre_id"
    t.integer "movie_id"
    t.index ["genre_id"], name: "index_movies_genres_on_genre_id"
    t.index ["movie_id", "genre_id"], name: "index_movies_genres_on_movie_id_and_genre_id", unique: true
    t.index ["movie_id"], name: "index_movies_genres_on_movie_id"
  end

  create_table "schedules", force: :cascade do |t|
    t.datetime "time"
    t.boolean "three_d"
    t.boolean "ov"
    t.string "info"
    t.integer "movie_id"
    t.integer "cinema_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "schedule_id"
    t.index ["cinema_id"], name: "index_schedules_on_cinema_id"
    t.index ["movie_id"], name: "index_schedules_on_movie_id"
    t.index ["time", "movie_id", "cinema_id"], name: "index_schedules_on_time_and_movie_id_and_cinema_id", unique: true
  end

  create_table "schedules_tags", id: false, force: :cascade do |t|
    t.integer "tag_id", null: false
    t.integer "schedule_id", null: false
    t.index ["tag_id", "schedule_id"], name: "index_schedules_tags_on_tag_id_and_schedule_id", unique: true
  end

  create_table "tags", force: :cascade do |t|
    t.string "tag_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end

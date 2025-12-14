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

ActiveRecord::Schema[8.1].define(version: 2025_12_10_220849) do
  create_table "bids", force: :cascade do |t|
    t.integer "actual_tricks"
    t.datetime "created_at", null: false
    t.integer "player_id", null: false
    t.integer "predicted_tricks"
    t.integer "round_id", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_bids_on_player_id"
    t.index ["round_id", "player_id"], name: "index_bids_on_round_id_and_player_id", unique: true
    t.index ["round_id"], name: "index_bids_on_round_id"
  end

  create_table "game_participations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "game_id", null: false
    t.integer "player_id", null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_game_participations_on_game_id"
    t.index ["player_id"], name: "index_game_participations_on_player_id"
  end

  create_table "games", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "current_round_number", default: 1
    t.datetime "ended_at"
    t.datetime "started_at"
    t.datetime "updated_at", null: false
  end

  create_table "players", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false, collation: "NOCASE"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_players_on_name", unique: true
  end

  create_table "rounds", force: :cascade do |t|
    t.integer "cards_dealt", null: false
    t.datetime "created_at", null: false
    t.integer "game_id", null: false
    t.boolean "has_trump", default: false, null: false
    t.integer "round_number", null: false
    t.integer "starts_at"
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_rounds_on_game_id"
  end

  add_foreign_key "bids", "players"
  add_foreign_key "bids", "rounds"
  add_foreign_key "game_participations", "games"
  add_foreign_key "game_participations", "players"
  add_foreign_key "rounds", "games"
end

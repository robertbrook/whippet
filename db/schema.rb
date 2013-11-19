# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20131119164548) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "business_items", force: true do |t|
    t.integer "time_block_id"
    t.string  "ident"
    t.text    "description"
    t.integer "position"
    t.string  "note"
    t.json    "meta"
  end

  add_index "business_items", ["ident"], name: "index_business_items_on_ident", using: :btree

  create_table "calendar_days", force: true do |t|
    t.string  "type"
    t.string  "ident"
    t.date    "date"
    t.string  "note"
    t.boolean "accepted"
    t.boolean "is_provisional"
    t.json    "history"
    t.json    "meta"
  end

  add_index "calendar_days", ["ident"], name: "index_calendar_days_on_ident", using: :btree

  create_table "recesses", force: true do |t|
    t.string  "name"
    t.date    "start_date"
    t.date    "finish_date"
    t.json    "meta"
    t.integer "year"
  end

  create_table "sitting_fridays", force: true do |t|
    t.date "sitting_friday"
    t.json "meta"
  end

  create_table "speaker_lists", force: true do |t|
    t.integer "time_block_id"
    t.string  "speaker"
    t.json    "meta"
  end

  create_table "time_blocks", force: true do |t|
    t.integer "sitting_day_id"
    t.string  "ident"
    t.integer "time_as_number"
    t.string  "title"
    t.string  "note"
    t.integer "position"
    t.json    "meta"
  end

  add_index "time_blocks", ["ident"], name: "index_time_blocks_on_ident", using: :btree

end

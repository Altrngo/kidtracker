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

ActiveRecord::Schema[8.1].define(version: 2026_06_10_200205) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "child_items", force: :cascade do |t|
    t.boolean "active"
    t.bigint "child_id", null: false
    t.datetime "created_at", null: false
    t.integer "green_points"
    t.bigint "item_id", null: false
    t.integer "red_points"
    t.datetime "updated_at", null: false
    t.integer "yellow_points"
    t.index ["child_id"], name: "index_child_items_on_child_id"
    t.index ["item_id"], name: "index_child_items_on_item_id"
  end

  create_table "children", force: :cascade do |t|
    t.string "avatar_color"
    t.datetime "created_at", null: false
    t.string "first_name"
    t.integer "total_points"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_children_on_user_id"
  end

  create_table "day_entries", force: :cascade do |t|
    t.bigint "child_item_id", null: false
    t.integer "computed_points", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "day_of_week", null: false
    t.string "emoji_state", default: "green", null: false
    t.datetime "updated_at", null: false
    t.bigint "week_id", null: false
    t.index ["child_item_id"], name: "index_day_entries_on_child_item_id"
    t.index ["week_id", "child_item_id", "day_of_week"], name: "index_day_entries_on_week_id_and_child_item_id_and_day_of_week", unique: true
    t.index ["week_id"], name: "index_day_entries_on_week_id"
  end

  create_table "items", force: :cascade do |t|
    t.boolean "active"
    t.string "category"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_items_on_user_id"
  end

  create_table "point_transactions", force: :cascade do |t|
    t.integer "amount", null: false
    t.bigint "child_id", null: false
    t.datetime "created_at", null: false
    t.bigint "privilege_id"
    t.string "reason", null: false
    t.datetime "updated_at", null: false
    t.index ["child_id"], name: "index_point_transactions_on_child_id"
    t.index ["privilege_id"], name: "index_point_transactions_on_privilege_id"
  end

  create_table "privileges", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "point_cost", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_privileges_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "weeks", force: :cascade do |t|
    t.bigint "child_id", null: false
    t.datetime "created_at", null: false
    t.boolean "finalized", default: false, null: false
    t.date "start_date", null: false
    t.datetime "updated_at", null: false
    t.integer "week_score", default: 0, null: false
    t.index ["child_id", "start_date"], name: "index_weeks_on_child_id_and_start_date", unique: true
    t.index ["child_id"], name: "index_weeks_on_child_id"
  end

  add_foreign_key "child_items", "children"
  add_foreign_key "child_items", "items"
  add_foreign_key "children", "users"
  add_foreign_key "day_entries", "child_items"
  add_foreign_key "day_entries", "weeks"
  add_foreign_key "items", "users"
  add_foreign_key "point_transactions", "children"
  add_foreign_key "point_transactions", "privileges"
  add_foreign_key "privileges", "users"
  add_foreign_key "weeks", "children"
end

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

ActiveRecord::Schema[7.2].define(version: 2026_06_20_075024) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "vector"

  create_table "categories", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "normalized_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "normalized_name"], name: "index_categories_on_user_id_and_normalized_name", unique: true
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "daily_log_embeddings", force: :cascade do |t|
    t.bigint "daily_log_id", null: false
    t.string "embedding_model", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.vector "embedding", limit: 1024
    t.index ["daily_log_id"], name: "index_daily_log_embeddings_on_daily_log_id", unique: true
  end

  create_table "daily_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "insights"
    t.index ["user_id", "date"], name: "index_daily_logs_on_user_id_and_date", unique: true
    t.index ["user_id"], name: "index_daily_logs_on_user_id"
  end

  create_table "learning_items", force: :cascade do |t|
    t.bigint "daily_log_id", null: false
    t.bigint "category_id", null: false
    t.text "summary"
    t.integer "duration_minutes"
    t.integer "lock_version", default: 0, null: false
    t.string "client_uuid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_learning_items_on_category_id"
    t.index ["daily_log_id"], name: "index_learning_items_on_daily_log_id"
  end

  create_table "monthly_goals", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "month", null: false
    t.string "goal1", null: false
    t.string "goal2", null: false
    t.string "goal3", null: false
    t.boolean "completed1", default: false, null: false
    t.boolean "completed2", default: false, null: false
    t.boolean "completed3", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "month"], name: "index_monthly_goals_on_user_id_and_month", unique: true
    t.index ["user_id"], name: "index_monthly_goals_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "categories", "users"
  add_foreign_key "daily_log_embeddings", "daily_logs"
  add_foreign_key "daily_logs", "users"
  add_foreign_key "learning_items", "categories"
  add_foreign_key "learning_items", "daily_logs"
  add_foreign_key "monthly_goals", "users"
end

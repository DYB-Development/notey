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

ActiveRecord::Schema[8.1].define(version: 2026_09_21_000001) do
  create_table "members", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.datetime "updated_at", null: false
  end

  create_table "notey_attempts", force: :cascade do |t|
    t.string "channel", null: false
    t.datetime "created_at", null: false
    t.text "failure"
    t.integer "notification_id", null: false
    t.string "state", default: "claimed", null: false
    t.datetime "updated_at", null: false
    t.index ["notification_id", "channel"], name: "index_notey_attempts_unique", unique: true
    t.index ["notification_id"], name: "index_notey_attempts_on_notification_id"
  end

  create_table "notey_destinations", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "address", null: false
    t.string "channel", null: false
    t.datetime "created_at", null: false
    t.text "credential"
    t.integer "member_id"
    t.string "member_type"
    t.datetime "updated_at", null: false
    t.index ["member_type", "member_id", "account_id", "channel"], name: "index_notey_destinations_unique", unique: true
    t.index ["member_type", "member_id"], name: "index_notey_destinations_on_member"
  end

  create_table "notey_digests", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "digest_window", null: false
    t.integer "member_id", null: false
    t.string "member_type", null: false
    t.integer "notifications_count", default: 0, null: false
    t.datetime "period_start", null: false
    t.datetime "sent_at"
    t.datetime "updated_at", null: false
    t.index ["member_type", "member_id", "account_id", "digest_window", "period_start"], name: "index_notey_digests_unique", unique: true
    t.index ["member_type", "member_id"], name: "index_notey_digests_on_member"
  end

  create_table "notey_preferences", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.json "channels", default: [], null: false
    t.datetime "created_at", null: false
    t.string "digest_window", default: "immediate", null: false
    t.integer "member_id", null: false
    t.string "member_type", null: false
    t.string "notification_type", null: false
    t.datetime "updated_at", null: false
    t.index ["digest_window"], name: "index_notey_preferences_on_digest_window"
    t.index ["member_type", "member_id", "account_id", "notification_type"], name: "index_notey_preferences_unique", unique: true
    t.index ["member_type", "member_id"], name: "index_notey_preferences_on_member"
  end

  create_table "noticed_events", force: :cascade do |t|
    t.bigint "account_id"
    t.datetime "created_at", null: false
    t.integer "notifications_count"
    t.json "params"
    t.bigint "record_id"
    t.string "record_type"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id"], name: "index_noticed_events_on_record"
  end

  create_table "noticed_notifications", force: :cascade do |t|
    t.bigint "account_id"
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.datetime "read_at", precision: nil
    t.bigint "recipient_id", null: false
    t.string "recipient_type", null: false
    t.datetime "seen_at", precision: nil
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_noticed_notifications_on_event_id"
    t.index ["recipient_type", "recipient_id"], name: "index_noticed_notifications_on_recipient"
  end

  add_foreign_key "notey_attempts", "noticed_notifications", column: "notification_id", on_delete: :cascade
end

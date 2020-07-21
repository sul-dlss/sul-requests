# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_07_20_233617) do

  create_table "admin_comments", force: :cascade do |t|
    t.string "commenter"
    t.string "comment"
    t.integer "request_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "messages", force: :cascade do |t|
    t.text "text"
    t.datetime "start_at"
    t.datetime "end_at"
    t.string "library"
    t.string "request_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "requests", force: :cascade do |t|
    t.string "type"
    t.date "needed_date"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "origin"
    t.string "destination"
    t.string "origin_location"
    t.string "item_id"
    t.integer "user_id"
    t.text "data"
    t.text "item_title"
    t.text "barcodes"
    t.string "estimated_delivery"
    t.integer "approval_status", default: 0
    t.boolean "via_borrow_direct", default: false
    t.index ["needed_date"], name: "index_requests_on_needed_date"
    t.index ["user_id"], name: "index_requests_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "webauth"
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "library_id"
    t.string "student_type"
    t.index ["email"], name: "index_users_on_email"
    t.index ["library_id"], name: "index_users_on_library_id"
    t.index ["webauth"], name: "index_users_on_webauth"
  end

end

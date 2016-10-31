# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20161028235652) do

  create_table "admin_comments", force: :cascade do |t|
    t.string   "commenter"
    t.string   "comment"
    t.integer  "request_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "messages", force: :cascade do |t|
    t.text     "text"
    t.datetime "start_at"
    t.datetime "end_at"
    t.string   "library"
    t.string   "request_type"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "requests", force: :cascade do |t|
    t.string   "type"
    t.date     "needed_date"
    t.string   "status"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "origin"
    t.string   "destination"
    t.string   "origin_location"
    t.string   "item_id"
    t.integer  "user_id"
    t.text     "data"
    t.text     "item_title"
    t.text     "barcodes"
    t.string   "estimated_delivery"
    t.integer  "approval_status",    default: 0
  end

  add_index "requests", ["needed_date"], name: "index_requests_on_needed_date"
  add_index "requests", ["user_id"], name: "index_requests_on_user_id"

  create_table "users", force: :cascade do |t|
    t.string   "webauth"
    t.string   "name"
    t.string   "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "library_id"
  end

  add_index "users", ["email"], name: "index_users_on_email"
  add_index "users", ["library_id"], name: "index_users_on_library_id"
  add_index "users", ["webauth"], name: "index_users_on_webauth"

end

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

ActiveRecord::Schema.define(version: 2021_01_04_195914) do

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.integer "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end

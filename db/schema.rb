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

ActiveRecord::Schema[8.1].define(version: 2026_02_06_002343) do
  create_table "admin_comments", force: :cascade do |t|
    t.string "commenter"
    t.string "comment"
    t.integer "request_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "request_type", default: "Request"
    t.index ["request_type", "request_id"], name: "index_admin_comments_on_request_type_and_request_id"
  end

  create_table "folio_command_logs", force: :cascade do |t|
    t.string "pickup_location_id", null: false
    t.string "user_id", null: false
    t.string "barcode", null: false
    t.string "item_id", null: false
    t.string "patron_comments"
    t.date "expiration_date", null: false
    t.integer "request_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["request_id"], name: "index_folio_command_logs_on_request_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "text"
    t.datetime "start_at", precision: nil
    t.datetime "end_at", precision: nil
    t.string "library"
    t.string "request_type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "patron_requests", force: :cascade do |t|
    t.string "patron_id"
    t.string "patron_email"
    t.string "display_type"
    t.string "instance_hrid"
    t.date "needed_date"
    t.string "service_point_code"
    t.text "data", limit: 4294967295
    t.string "fulfillment_type"
    t.string "status"
    t.string "folio_request_id"
    t.string "origin_location_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "mediation_status"
    t.string "request_type"
    t.index ["display_type"], name: "index_patron_requests_on_display_type"
    t.index ["folio_request_id"], name: "index_patron_requests_on_folio_request_id"
    t.index ["instance_hrid"], name: "index_patron_requests_on_instance_hrid"
    t.index ["mediation_status"], name: "index_patron_requests_on_mediation_status"
    t.index ["needed_date"], name: "index_patron_requests_on_needed_date"
    t.index ["origin_location_code"], name: "index_patron_requests_on_origin_location_code"
    t.index ["patron_id"], name: "index_patron_requests_on_patron_id"
    t.index ["request_type"], name: "index_patron_requests_on_request_type"
  end

  create_table "requests", force: :cascade do |t|
    t.string "type"
    t.date "needed_date"
    t.string "status"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.string "sunetid"
    t.string "name"
    t.string "email"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "library_id"
    t.string "student_type"
    t.string "univ_id"
    t.index ["email"], name: "index_users_on_email"
    t.index ["library_id"], name: "index_users_on_library_id"
    t.index ["sunetid"], name: "unique_users_by_sunetid", unique: true
  end

end

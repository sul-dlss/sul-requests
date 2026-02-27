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

ActiveRecord::Schema[8.1].define(version: 2026_02_27_200721) do
  create_table "admin_comments", force: :cascade do |t|
    t.string "comment"
    t.string "commenter"
    t.datetime "created_at", precision: nil, null: false
    t.integer "request_id"
    t.string "request_type", default: "Request"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["request_type", "request_id"], name: "index_admin_comments_on_request_type_and_request_id"
  end

  create_table "api_responses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "item_id"
    t.integer "patron_request_id", null: false
    t.binary "request_data"
    t.binary "response_data"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_api_responses_on_item_id"
    t.index ["patron_request_id"], name: "index_api_responses_on_patron_request_id"
  end

  create_table "messages", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "end_at", precision: nil
    t.string "library"
    t.string "request_type"
    t.datetime "start_at", precision: nil
    t.text "text"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "patron_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "data"
    t.string "display_type"
    t.string "folio_request_id"
    t.string "fulfillment_type"
    t.string "instance_hrid"
    t.string "mediation_status"
    t.date "needed_date"
    t.string "origin_location_code"
    t.string "patron_email"
    t.string "patron_id"
    t.string "request_type"
    t.string "service_point_code"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["display_type"], name: "index_patron_requests_on_display_type"
    t.index ["folio_request_id"], name: "index_patron_requests_on_folio_request_id"
    t.index ["instance_hrid"], name: "index_patron_requests_on_instance_hrid"
    t.index ["mediation_status"], name: "index_patron_requests_on_mediation_status"
    t.index ["needed_date"], name: "index_patron_requests_on_needed_date"
    t.index ["origin_location_code"], name: "index_patron_requests_on_origin_location_code"
    t.index ["patron_id"], name: "index_patron_requests_on_patron_id"
    t.index ["request_type"], name: "index_patron_requests_on_request_type"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "email"
    t.string "library_id"
    t.string "name"
    t.string "student_type"
    t.string "sunetid"
    t.string "univ_id"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["email"], name: "index_users_on_email"
    t.index ["library_id"], name: "index_users_on_library_id"
    t.index ["sunetid"], name: "unique_users_by_sunetid", unique: true
  end

  add_foreign_key "api_responses", "patron_requests"
end

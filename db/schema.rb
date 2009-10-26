# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090924224246) do

  create_table "fields", :force => true do |t|
    t.string   "field_name"
    t.string   "field_label"
    t.integer  "field_order"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fields_requestdefs", :id => false, :force => true do |t|
    t.integer  "field_id",      :null => false
    t.integer  "requestdef_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "libraries", :force => true do |t|
    t.string   "lib_code"
    t.string   "lib_descrip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "libraries_pickupkeys", :id => false, :force => true do |t|
    t.integer  "library_id",   :null => false
    t.integer  "pickupkey_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pickupkeys", :force => true do |t|
    t.string   "pickup_key"
    t.string   "pickup_descrip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "requestdefs", :force => true do |t|
    t.string   "name"
    t.string   "library"
    t.string   "current_loc"
    t.string   "req_status"
    t.string   "req_type"
    t.boolean  "enabled"
    t.boolean  "authenticated"
    t.boolean  "unauthenticated"
    t.string   "title"
    t.text     "initial_text"
    t.text     "final_text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end

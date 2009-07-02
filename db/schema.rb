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

ActiveRecord::Schema.define(:version => 20090610000513) do

  create_table "forms", :force => true do |t|
    t.string   "form_id"
    t.string   "title"
    t.string   "heading"
    t.string   "before_fields"
    t.string   "after_fields"
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  
    create_table "request_types", :force => true do |t|
    t.string   "type"
    t.string   "current_loc"
    t.string   "req_status"
    t.string   "form"
    t.string   "text"
    t.boolean  "enabled"
    t.boolean  "authenticated"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end

class CreateReqtests < ActiveRecord::Migration
  def self.up
    create_table :reqtests do |t|
      t.string :req_def
      t.string :socrates_link
      t.string :form_status
      t.string :request_status
      t.text :comments

      t.timestamps
    end
  end

  def self.down
    drop_table :reqtests
  end
end

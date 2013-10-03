class Requestdef < ActiveRecord::Base
  has_and_belongs_to_many :fields
  validates_presence_of :name, :library, :current_loc
  
  attr_accessible :name, :library, :current_loc, :req_status, :req_type, :enabled, :authenticated, :unauthenticated, :title, :initial_text, :extra_text, :final_text
  
  def available_fields
    #Field.find(:all, :order => "field_order ASC")
    Field.order("field_order ASC").all
  end
  
  def chosen?(field)
    fields.include?(field)
  end
end

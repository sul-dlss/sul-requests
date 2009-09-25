class Requestdef < ActiveRecord::Base
  has_and_belongs_to_many :fields
  validates_presence_of :name, :library, :current_loc, :req_type
  
  def available_fields
    Field.find(:all, :order => "field_order ASC")
  end
  
  def chosen?(field)
    fields.include?(field)
  end
end

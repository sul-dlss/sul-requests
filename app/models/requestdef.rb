class Requestdef < ActiveRecord::Base
  has_and_belongs_to_many :fields
  validates_presence_of :name, :library, :current_loc, :req_type
end

class Field < ActiveRecord::Base
  has_and_belongs_to_many :requestdefs
  validates_presence_of :field_name, :field_label
end

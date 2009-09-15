class Library < ActiveRecord::Base
  has_and_belongs_to_many :pickupkeys
end

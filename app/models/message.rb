class Message < ActiveRecord::Base
  validates_presence_of :msg_number, :msg_text
end

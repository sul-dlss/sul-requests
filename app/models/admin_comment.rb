# frozen_string_literal: true

##
# A class to store admin comments on requests
class AdminComment < ActiveRecord::Base
  belongs_to :request

  validates :comment, :commenter, presence: true
end

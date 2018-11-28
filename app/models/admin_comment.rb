# frozen_string_literal: true

##
# A class to store admin comments on requests
class AdminComment < ActiveRecord::Base
  belongs_to :request, optional: true

  validates :comment, :commenter, presence: true
end

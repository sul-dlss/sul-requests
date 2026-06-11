# frozen_string_literal: true

# :nodoc:
class AeonRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :aeon }
end

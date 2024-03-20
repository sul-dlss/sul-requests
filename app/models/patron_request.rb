# frozen_string_literal: true

###
#  Main Request class for Requests WC.
###
class PatronRequest < ApplicationRecord
  class_attribute :bib_model_class, default: Settings.ils.bib_model.constantize

  def bib_data
    @bib_data ||= begin
      # Append "a" to the item_id unless it already starts with a letter (e.g. "in00000063826")
      hrid = instance_hrid.start_with?(/\d/) ? "a#{instance_hrid}" : instance_hrid
      bib_model_class.fetch(hrid)
    end
  end

  def item_title
    bib_data&.title
  end
end

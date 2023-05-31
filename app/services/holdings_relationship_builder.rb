# frozen_string_literal: true

# Factory for the "holdings" relationship. This abstracts away the difference between Searchworks and Folio as the backing store.
class HoldingsRelationshipBuilder
  # @param [Request] request the users request
  # @param [Searchworks::Item, Folio::BibData] bib_data the record from the ILS
  def self.build(request, bib_data)
    if bib_data.is_a? Folio::BibData
      Folio::Holdings.new(request, bib_data.instance_id)
    else
      Searchworks::Holdings.new(request, bib_data.holdings)
    end
  end
end

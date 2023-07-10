# frozen_string_literal: true

# Factory for the "holdings" relationship. This abstracts away the difference between Searchworks and Folio as the backing store.
class HoldingsRelationshipBuilder
  # @param [Request] request the users request
  # @param [Searchworks::Item, Folio::Instance] bib_data the record from the ILS
  def self.build(request)
    request.bib_data&.request_holdings(request) || []
  end
end

# frozen_string_literal: true

def stub_folio_instance_json(folio_instance)
  allow(Folio::Instance).to receive(:fetch).and_return(folio_instance)
  allow_any_instance_of(FolioGraphqlClient).to receive(:item_circulation_status).and_return([]) # rubocop:disable RSpec/AnyInstance
end

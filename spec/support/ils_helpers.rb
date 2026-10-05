# frozen_string_literal: true

def stub_folio_instance_json(folio_instance)
  allow(Folio::Instance).to receive(:fetch).and_return(folio_instance)
end

def stub_folio_patron(**)
  instance_double(Folio::Patron, key: '513a9054-5897-11ee-8c99-0242ac120002', fines: [], checkouts: [], requests: [], ilb_eligible?: false,
                                 **)
end

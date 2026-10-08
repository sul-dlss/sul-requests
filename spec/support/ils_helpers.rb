# frozen_string_literal: true

def stub_folio_instance_json(folio_instance)
  allow(Folio::Instance).to receive(:fetch).and_return(folio_instance)
end

def stub_folio_patron(key: '513a9054-5897-11ee-8c99-0242ac120002', **)
  instance_double(Folio::Patron, id: key, key: key, email: 'test@example.com',
                                 sponsors: [],
                                 fines: [], checkouts: [], requests: [],
                                 ilb_eligible?: false, patron_group_name: nil,
                                 **)
end

# frozen_string_literal: true

def stub_bib_data_json(bib_data)
  allow(Folio::Instance).to receive(:fetch).and_return(bib_data)
end

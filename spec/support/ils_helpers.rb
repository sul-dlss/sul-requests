# frozen_string_literal: true

def stub_bib_data_json(bib_data)
  allow(Settings.ils.bib_model.constantize).to receive(:fetch).and_return(bib_data)
end

def stub_symphony_response(response)
  allow_any_instance_of(Request).to receive(:symphony_response_data).and_return(response)
end

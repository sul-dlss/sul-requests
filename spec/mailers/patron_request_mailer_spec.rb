# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PatronRequestMailer do
  let(:mail) { described_class.confirmation_email(request) }
  let(:patron) { build(:patron) }
  let(:request) do
    PatronRequest.new(instance_hrid: 'a12345', patron_email: patron.email, patron:, patron_request_items_attributes: [{ item_id: 'x' }],
                      origin_location_code: 'SAL3-STACKS', request_type:, folio_instance: folio_instance)
  end
  let(:folio_instance) do
    build(:single_holding,
          items: [build(:item, id: 'x',
                               effective_location: build(:law_location))])
  end

  before do
    allow(request).to receive_messages(patron:)
  end

  context 'pickup request_type' do
    let(:request_type) { 'pickup' }

    it 'tests pickup confirmation email' do
      expect(mail.subject).to eq('Item Title - Stanford University Libraries request confirmation')
      expect(mail.to).to eq(['test@example.com'])
      expect(mail.from).to eq(['greencirc@stanford.edu'])
      expect(mail.body).to include('We received your pickup request!')
      expect(mail.body).to include('<dt>Title:</dt><dd>Item Title</dd>')
      expect(mail.body).to include('In library use only')
      expect(mail.body).to include('ABC 123')
    end

    context 'when the bib record has a document_type that triggers icon rendering' do
      before do
        allow(request.bib_record).to receive_messages(document_type: 'Book', document_formats: ['Book'])
      end

      it 'renders the format indicator without raising for the missing helper' do
        expect { mail.body }.not_to raise_error
        expect(mail.body).to include('Book')
      end
    end
  end

  context 'scan request_type' do
    let(:request_type) { 'scan' }

    it 'tests scan confirmation email' do
      expect(mail.subject).to eq('Item Title - Stanford University Libraries request confirmation')
      expect(mail.to).to eq(['test@example.com'])
      expect(mail.from).to eq(['scan-and-deliver@stanford.edu'])
      expect(mail.body).to include('We received your digital scan request!')
      expect(mail.body).to include('<dt>Title:</dt><dd>Item Title</dd>')
    end
  end
end

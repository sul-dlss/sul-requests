# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PatronRequestMailer do
  let(:mail) { described_class.confirmation_email(request) }
  let(:patron) do
    instance_double(Folio::Patron, id: '', email: 'test@test.com', patron_group_id: '3684a786-6671-4268-8ed0-9db82ebca60b',
                                   allowed_request_types: ['Page'])
  end
  let(:request) do
    PatronRequest.new(instance_hrid: 'a12345', patron_email: patron.email, patron:, barcodes: ['12345678'],
                      origin_location_code: 'SAL3-STACKS', request_type:)
  end

  before do
    allow(request).to receive_messages(patron:, bib_data: build(:single_holding,
                                                                items: [build(:item, effective_location: build(:law_location))]))
  end

  context 'pickup request_type' do
    let(:request_type) { 'pickup' }

    it 'tests pickup confirmation email' do
      expect(mail.subject).to eq('Item Title - Stanford University Libraries request confirmation')
      expect(mail.to).to eq(['test@test.com'])
      expect(mail.from).to eq(['greencirc@stanford.edu'])
      expect(mail.body).to include('We received your pickup request!')
      expect(mail.body).to include('Item: Item Title')
    end
  end

  context 'scan request_type' do
    let(:request_type) { 'scan' }

    it 'tests scan confirmation email' do
      expect(mail.subject).to eq('Item Title - Stanford University Libraries request confirmation')
      expect(mail.to).to eq(['test@test.com'])
      expect(mail.from).to eq(['greencirc@stanford.edu'])
      expect(mail.body).to include('We received your scan request!')
      expect(mail.body).to include('Item: Item Title')
    end
  end
end

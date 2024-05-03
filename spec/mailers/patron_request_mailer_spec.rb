# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PatronRequestMailer do
  let(:mail) { described_class.confirmation_email(request) }
  let(:patron) { build(:patron) }
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
      expect(mail.to).to eq(['test@example.com'])
      expect(mail.from).to eq(['greencirc@stanford.edu'])
      expect(mail.body).to include('We received your pickup request!')
      expect(mail.body).to include('<dt>Title:</dt><dd>Item Title</dd>')
    end
  end

  context 'scan request_type' do
    let(:request_type) { 'scan' }

    it 'tests scan confirmation email' do
      expect(mail.subject).to eq('Item Title - Stanford University Libraries request confirmation')
      expect(mail.to).to eq(['test@example.com'])
      expect(mail.from).to eq(['scan-and-deliver@stanford.edu'])
      expect(mail.body).to include('We received your scan request!')
      expect(mail.body).to include('<dt>Title:</dt><dd>Item Title</dd>')
    end
  end
end

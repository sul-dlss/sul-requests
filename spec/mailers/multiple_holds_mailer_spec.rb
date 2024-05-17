# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultipleHoldsMailer do
  let(:patron_request) do
    build(:page_patron_request, service_point_code: 'GREEN-LOAN', patron: nil)
  end

  let(:item) do
    instance_double(Folio::Item, barcode: '36105xxx')
  end

  describe '#multiple_holds_notification' do
    let(:mail) { described_class.multiple_holds_notification(patron_request, item) }

    it 'has correct fields' do
      expect(mail.subject).to eq 'Multiple pages for HOLD@GR'
      expect(mail.to).to include 'sulcirchelp@stanford.edu'
    end

    it 'body has things' do
      expect(mail.body.to_s).to include 'Multiple HOLD@GR pages for the following item'
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultipleHoldsMailer, type: :mailer do
  let(:options) do
    { patron_barcode: 'HOLD@foo' }
  end

  describe '#multiple_holds_notification' do
    let(:mail) { described_class.multiple_holds_notification(options) }

    it 'has correct fields' do
      expect(mail.subject).to eq 'Multiple pages for HOLD@foo'
      expect(mail.to).to include 'sulcirchelp@stanford.edu'
    end

    it 'body has things' do
      expect(mail.body.to_s).to include 'Multiple HOLD@foo pages for the following item'
    end
  end
end

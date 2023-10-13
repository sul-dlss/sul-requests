# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Illiadable do
  subject(:request) { build_stubbed(:scan, :with_holdings) }

  describe '#notify_ilb!' do
    it 'sends an email' do
      expect { request.notify_ilb! }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
    end
  end

  describe '#illiad_error?' do
    it 'is false' do
      expect(request).not_to be_illiad_error
    end

    context 'when illiad responded with a message' do
      before do
        request.illiad_response_data = { 'Message' => 'Something went wrong' }
      end

      it 'is true' do
        expect(request).to be_illiad_error
      end
    end
  end
end

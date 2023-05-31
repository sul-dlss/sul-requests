# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestStatusMailerFactory do
  subject(:mailer) { described_class.for(request) }

  let(:holdings_relationship) { double(:relationship, where: selected_items, all: [], single_checked_out_item?: false) }
  let(:selected_items) { [] }

  before do
    allow(HoldingsRelationshipBuilder).to receive(:build).and_return(holdings_relationship)
    request.user = create(:anon_user)
  end

  describe 'user errors' do
    describe 'Error U003' do
      let(:request) { create(:page_with_holdings, symphony_response_data: { usererr_code: 'U003' }) }

      it 'sends the correct email based on the user error code' do
        expect(mailer.body.to_s).to include 'We were unable to process your request because your status is BLOCKED'
      end
    end

    describe 'Errors that we do not have a specific email for' do
      let(:request) { create(:page_with_holdings, symphony_response_data: { usererr_code: 'P004' }) }

      it 'sends a generic symphony error email' do
        expect(mailer.body.to_s).to include 'Something went wrong and we were unable to process your request'
      end
    end
  end

  describe 'request types' do
    describe 'scan' do
      let(:request) { create(:scan, :without_validations) }

      it 'send the correct mail based on the type of the request' do
        expect(mailer.body.to_s).to include 'The following items have been queued for scanning'
      end
    end

    describe 'page' do
      let(:request) { create(:page) }

      it 'send the correct mail based on the type of the request' do
        expect(mailer.body.to_s).to include 'The following item(s) will be delivered to'
      end
    end
  end
end

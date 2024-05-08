# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MediationMailer do
  describe 'mediator_notification' do
    let(:request) { create(:mediated_patron_request) }
    let(:mediator_contact_info) { { request.origin_library_code => { email: 'someone@example.com' } } }
    before do
      allow(Rails.application.config).to receive(:mediator_contact_info).and_return(mediator_contact_info)
    end

    let(:mail) { described_class.mediator_notification(request) }

    describe 'to' do
      it 'is the origin contact email address' do
        expect(mail.to).to eq ['someone@example.com']
      end
    end

    describe 'from' do
      it 'is the configured from address for the origin' do
        expect(mail.from).to eq ['artlibrary@stanford.edu']
      end

      describe 'location specific' do
        let(:request) { create(:page_mp_mediated_patron_request) }

        it 'is the configured from address for the origin' do
          expect(mail.from).to eq ['brannerlibrary@stanford.edu']
        end
      end
    end

    describe 'subject' do
      it 'is the default' do
        expect(mail.subject).to eq 'New request needs mediation'
      end
    end

    describe 'body' do
      let(:request) do
        create(:mediated_patron_request_with_holdings, barcodes: ['12345678'])
      end

      let(:body) { mail.body.to_s }

      it 'has the date' do
        date_str = I18n.l(request.created_at, format: :short)
        expect(body).to include "On #{date_str}, Test User <test@example.com> requested the following:"
      end

      it 'has the title' do
        expect(body).to include(request.item_title)
      end

      it 'has holdings information' do
        expect(body).to include('Item(s) requested:')
        expect(body).to include('ABC 123')
      end

      it 'has a planned date of visit' do
        expect(body).to include "I plan to visit on: #{I18n.l request.needed_date, format: :quick}"
      end

      it 'has a link to the mediation page' do
        expect(body).to include 'Login to view and approve the request at http://'
      end
    end
  end
end

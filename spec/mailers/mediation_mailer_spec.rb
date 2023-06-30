# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MediationMailer do
  let(:folio_stub) { :empty }

  before do
    stub_folio_holdings(folio_stub)
  end

  describe 'mediator_notification' do
    let(:user) { build(:non_sso_user) }
    let(:request) { create(:mediated_page, user:) }
    let(:mediator_contact_info) { { request.origin => { email: 'someone@example.com' } } }
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
        let(:request) { create(:page_mp_mediated_page, user:) }

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
      let(:folio_stub) { :folio_single_holding }

      let(:request) do
        create(:mediated_page_with_holdings, barcodes: ['12345678'], user:)
      end

      let(:body) { mail.body.to_s }

      it 'has the date' do
        date_str = I18n.l(request.created_at, format: :short)
        expect(body).to include "On #{date_str}, Jane Stanford (jstanford@stanford.edu) requested the following:"
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

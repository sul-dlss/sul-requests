# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IlbMailer do
  let(:patron_request) do
    instance_double(PatronRequest, id: 1, instance_hrid: 'a1234', persisted?: true, scan?: true,
                                   scan_title: 'Section Title for Scan 12345', scan_page_range: 'p. 1', scan_authors: nil,
                                   created_at: Time.zone.now, patron:, model_name: PatronRequest.model_name)
  end
  let(:patron) do
    build(:patron, personal: { firstName: 'Test', lastName: 'User', email: 'some-eligible-user@stanford.edu' }.deep_stringify_keys)
  end
  let(:bib_data) { build(:sal3_holdings) }

  before do
    allow(Folio::Instance).to receive(:fetch).with(patron_request.instance_hrid).and_return(bib_data)
    allow(patron_request).to receive(:to_model).and_return(patron_request)
  end

  describe 'failed_ilb_notification' do
    let(:mail) { described_class.failed_ilb_notification(patron_request) }

    describe 'to' do
      it 'is the origin contact email address' do
        expect(mail.to).to eq ['illiad-test@stanford.edu']
      end
    end

    describe 'from' do
      it 'is the configured from address for the origin' do
        expect(mail.from).to eq ['greencirc@stanford.edu']
      end
    end

    describe 'subject' do
      it 'is the default' do
        expect(mail.subject).to eq 'ILLiad request problem, please remediate'
      end
    end

    describe 'body' do
      let(:body) { mail.body.to_s }

      it 'has the date' do
        date_str = I18n.l(patron_request.created_at, format: :short)
        expect(body).to include "On #{date_str}, Test User <some-eligible-user@stanford.edu> requested the following:"
      end

      it 'has the searchworks link' do
        expect(body).to include('https://searchworks.stanford.edu/view/a1234')
      end

      it 'has item information' do
        expect(body).to include('Title:')
        expect(body).to include(' Section Title for Scan 12345')
      end

      context 'when the request is a scan' do
        it 'has a link to the request information' do
          expect(body).to include('http://example.com/patron_requests/')
        end
      end
    end
  end
end

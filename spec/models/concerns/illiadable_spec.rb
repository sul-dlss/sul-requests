# frozen_string_literal: true

require 'rails_helper'

# A fake Request type that can be sent to ILLiad
class ExampleRequest < Request
  include Illiadable
  clear_validators!
end

RSpec.describe Illiadable do
  subject(:request) { ExampleRequest.new(id: 1, item_id: '1234', user:, bib_data:) }

  let(:user) { create(:sso_user) }
  let(:patron) { instance_double(Folio::Patron, blocked?: false) }
  let(:bib_data) do
    instance_double(
      Folio::Instance,
      hrid: 'a1234',
      title: 'The title',
      isbn: '978-3-16-148410-0',
      oclcn: '(OCoLC-M)1294477572',
      pub_date: '2018',
      pub_place: 'Berlin',
      publisher: 'Walter de Gruyter GmbH',
      edition: '1st ed.',
      view_url: 'https://searchworks.stanford.edu/view/1234',
      request_holdings: holdings
    )
  end
  let(:holdings) do
    [
      instance_double(
        Folio::Item,
        barcode: '12345678',
        callnumber: 'ABC 321',
        enumeration: 'T.1 2023'
      )
    ]
  end

  before do
    allow(user).to receive(:patron).and_return(patron)
  end

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
        request.update(illiad_response_data: { 'Message' => 'Something went wrong' })
      end

      it 'is true' do
        expect(request).to be_illiad_error
      end
    end
  end
end

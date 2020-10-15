# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CdlCheckout do
  subject { described_class.new('druid', user) }

  let(:user) { create(:webauth_user) }
  let(:catalog_info) do
    instance_double(CatalogInfo,
                    callkey: 'xyz',
                    cdl_proxy_hold_item: instance_double(CatalogInfo, key: '1'),
                    loan_period: 2.hours,
                    items: items)
  end
  let(:symphony_client) { instance_double(SymphonyClient) }

  let(:items) do
    [
      instance_double(CatalogInfo, barcode: '12345',
                                   cdlable?: true,
                                   current_location: 'CDL-RESERVE')
    ]
  end

  before do
    allow(user).to receive(:patron).and_return(Patron.new({}))
    allow(SymphonyClient).to receive(:new).and_return(symphony_client)
  end

  # rubocop:disable RSpec/SubjectStub
  describe '.checkout' do
    before do
      allow(described_class).to receive(:new).with('druid', user).and_return(subject)
      allow(subject).to receive(:process_checkout).with('12345')
    end

    it 'calls #process_checkout' do
      described_class.checkout('12345', 'druid', user)

      expect(subject).to have_received(:process_checkout).with('12345')
    end

    context 'when symphony is unhappy' do
      it 'tries to eventually handle the checkout in a background job' do
        expect(subject).to receive(:process_checkout).with('12345').and_raise(Exceptions::SymphonyError).ordered
        expect(subject).to receive(:process_checkout).with('12345').and_return({}).ordered

        expect do
          expect { described_class.checkout('12345', 'druid', user) }.to raise_exception(Exceptions::SymphonyError)
        end.to have_performed_job(SubmitCdlCheckoutJob)
      end

      it 'sends the user a next-up email if the background checkout succeeds' do
        hold = instance_double(HoldRecord, circ_record: instance_double(CircRecord))
        expect(subject).to receive(:process_checkout).with('12345').and_raise(Exceptions::SymphonyError).ordered
        expect(subject).to receive(:process_checkout).with('12345').and_return({ hold: hold, token: 'xyz' }).ordered

        mailer = double(deliver_later: true)
        expect(CdlWaitlistMailer).to receive(:youre_up).with(hold, hold.circ_record).and_return(mailer)

        expect { described_class.checkout('12345', 'druid', user) }.to raise_exception(Exceptions::SymphonyError)
        expect(mailer).to have_received :deliver_later
      end
    end
  end

  describe '.checkin' do
    before do
      allow(described_class).to receive(:new).with(nil, user).and_return(subject)
      allow(subject).to receive(:process_checkin).with('holdrecordkey')
    end

    it 'calls #process_checkout' do
      described_class.checkin('holdrecordkey', user)

      expect(subject).to have_received(:process_checkin).with('holdrecordkey')
    end

    context 'when symphony is unhappy' do
      it 'tries to eventually handle the checkout in a background job' do
        expect(subject).to receive(:process_checkin).with('holdrecordkey').and_raise(Exceptions::SymphonyError).ordered
        expect(subject).to receive(:process_checkin).with('holdrecordkey').and_return({}).ordered

        expect do
          described_class.checkin('holdrecordkey', user)
        end.to have_performed_job(SubmitCdlCheckinJob)
      end
    end
  end
  # rubocop:enable RSpec/SubjectStub

  describe '#process_checkout' do
    # rubocop:disable RSpec/EmptyExampleGroup
    context 'with an existing hold and associated checkout' do
      pending 'gives you the active token'
    end

    context 'with an existing hold' do
      pending 'updates the existing hold the the checkout'
    end

    context 'when all eligible items are in use' do
      pending 'places a hold and renders something about a waitlist'
    end

    context 'when there is a choice if eligible items' do
      pending 'places a hold and picks one of the items using some criteria'
    end
    # rubocop:enable RSpec/EmptyExampleGroup

    it 'places the hold, checks the item out, and creates a token' do
      allow(CatalogInfo).to receive(:find).with('abc123').and_return(catalog_info)

      expect(symphony_client).to receive(:place_hold).and_return({})
      expect(symphony_client).to receive(:check_out_item).with('12345', 'CDL-CHECKEDOUT', dueDate: anything).and_return(
        {
          'circRecord' => {
            'fields' => {
              'dueDate' => '2099-08-25T23:59:00-07:00'
            }
          }
        }
      )
      expect(symphony_client).to receive(:update_hold).and_return({})

      payload = subject.process_checkout('abc123')
      expect(payload[:token]).to include sub: user.webauth
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestsHelper do
  include ApplicationHelper

  describe '#select_for_pickup_destinations' do
    let(:form) { double('form') }

    before do
      allow(form).to receive_messages(object: request)
    end

    describe 'single library' do
      let(:request) { build(:request, origin: 'SAL3', origin_location: 'SAL3-PAGE-EN', bib_data:) }
      let(:item) do
        build(:item,
              barcode: '3610512345678',
              callnumber: 'ABC 123',
              permanent_location: build(:page_en_location),
              effective_location: build(:page_en_location))
      end

      let(:bib_data) { double(:bib_data, title: 'Test title', request_holdings: [item]) }

      it 'returns library text and a hidden input w/ the destination library' do
        expect(form).to receive(:hidden_field).with(:destination, value: 'ENG').and_return('<hidden_field>')
        markup = Capybara.string(select_for_pickup_destinations(form))
        expect(markup).to have_css('.form-group .col-form-label', text: 'Will be delivered to')
        expect(markup).to have_css('.form-group .input-like-text', text: 'Engineering Library (Terman)')
        expect(markup).to have_css('hidden_field')
      end
    end

    describe 'multiple libraries' do
      let(:request) { create(:request, origin: 'SAL3', origin_location: 'SAL3-PAGE-HP') }

      it 'attempts to create a select list' do
        expect(form).to receive(:select).with(any_args).and_return('<select>')
        expect(select_for_pickup_destinations(form)).to eq '<select>'
      end

      context 'with a destination' do
        let(:request) { create(:request, origin: 'SAL3', destination: 'ART', origin_location: 'SAL3-PAGE-HP') }

        it 'defaults to the destination library' do
          expect(form).to receive(:select).with(anything, anything, hash_including(selected: 'ART'), anything)
            .and_return('<select>')
          expect(select_for_pickup_destinations(form)).to eq '<select>'
        end
      end
    end
  end

  describe '#label_for_pickup_destinations_dropdown' do
    it 'is "Deliver to" when if there are mutliple possiblities' do
      expect(label_for_pickup_destinations_dropdown(%w(GREEN MUSIC))).to eq 'Deliver to'
    end

    it 'is "Will be delivered to" when there is only one possibility' do
      expect(label_for_pickup_destinations_dropdown(['GREEN'])).to eq 'Will be delivered to'
    end
  end

  describe '#searchworks_link' do
    it 'constructs a searchworks link including the passed in html_options' do
      result = '<a data-elt-opt="somebehavior" href="https://searchworks.stanford.edu/view/234">A title</a>'
      expect(searchworks_link('234', 'A title', 'data-elt-opt' => 'somebehavior')).to eq result
    end
  end

  describe 'requester info' do
    let(:sso_user) { User.create(sunetid: 'jstanford', email: 'jstanford@stanford.edu') }
    let(:non_sso_user) { User.create(name: 'Joe', email: 'joe@xyz.com') }
    let(:library_id_user) { User.create(library_id: '123456') }

    it 'constructs requester info for SSO user' do
      expect(requester_info(sso_user)).to eq '<a href="mailto:jstanford@stanford.edu">jstanford@stanford.edu</a>'
    end

    it 'constructs requester info for non-SSO user' do
      expect(requester_info(non_sso_user)).to eq '<a href="mailto:joe@xyz.com">Joe (joe@xyz.com)</a>'
    end

    it 'constructs requester info for a library id user' do
      expect(requester_info(library_id_user)).to eq '123456'
    end
  end

  describe 'status_text_for_item' do
    let(:item) do
      Folio::Item.new(
        barcode: '123',
        type: 'LC',
        callnumber: '456',
        material_type: 'book',
        permanent_location: nil,
        effective_location:,
        status: item_status
      ).with_status(request_status)
    end

    let(:item_status) { 'Available' }
    let(:effective_location) { instance_double(Folio::Location, code: 'XYZ') }

    let(:request_status) do
      double(
        'status',
        errored?: false
      )
    end

    context 'with a user error' do
      let(:request_status) do
        double(
          'status',
          errored?: true,
          user_error_text: 'User is blocked'
        )
      end

      it 'returns the request status text if the item errored' do
        expect(status_text_for_item(item)).to eq 'User is blocked'
      end
    end

    context 'with a paged item' do
      before do
        allow(item).to receive(:paged?).and_return(true)
      end

      it 'returns text for page items' do
        expect(status_text_for_item(item)).to eq 'Paged'
      end
    end

    context 'with a held item' do
      let(:item_status) { 'Awaiting pickup' }

      it 'returns text for hold items' do
        expect(status_text_for_item(item)).to eq 'Item is on-site - hold for patron'
      end
    end

    context 'with other items' do
      let(:item_status) { 'In process' }

      it 'returns text for hold items' do
        expect(status_text_for_item(item)).to eq 'Added to pick list'
      end
    end
  end

  describe 'i18n_location_title_key' do
    subject { helper.i18n_location_title_key }

    let(:current_request) { double('request', holdings: [holding], origin_location:) }
    let(:origin_location) { '' }

    before { expect(helper).to receive_messages(current_request:) }

    context 'when the the item is in-process' do
      let(:holding) do
        Folio::Item.new(
          barcode: '123',
          type: 'LC',
          callnumber: '456',
          material_type: 'book',
          permanent_location: nil,
          effective_location: nil,
          status: 'In process'
        )
      end

      it { is_expected.to eq 'INPROCESS' }
    end

    context 'when the item is available' do
      let(:origin_location) { 'MARINE-BIO' }
      let(:holding) do
        Folio::Item.new(
          barcode: '123',
          type: 'LC',
          callnumber: '456',
          material_type: 'book',
          permanent_location: nil,
          effective_location: nil,
          status: 'Available'
        )
      end

      it { is_expected.to eq 'MARINE-BIO' }
    end
  end

  describe 'label_for_item_selector_holding' do
    let(:subject) { Capybara.string(label_for_item_selector_holding(holding)) }

    describe 'checked out items' do
      let(:holding) do
        Folio::Item.new(
          barcode: '123',
          type: 'LC',
          callnumber: '456',
          material_type: 'book',
          permanent_location: nil,
          effective_location: nil,
          status: 'Checked out',
          due_date: '2023-08-30'
        )
      end

      it 'includes the unavailable class' do
        expect(subject).to have_css('.unavailable')
      end

      it 'includes the due date' do
        expect(subject).to have_content('Due Aug 30, 2023')
      end
    end

    describe 'with a in-library use only item' do
      let(:holding) do
        build(:page_en_holdings).items.first
      end

      it 'includes the status icon' do
        expect(subject).to have_css('.noncirc')
      end

      it 'includes the status text' do
        expect(subject).to have_content('In-library use only')
      end
    end

    describe 'with a non-pageable item' do
      let(:holding) do
        build(:aged_to_lost_holdings).items.first
      end

      it 'includes the status icon' do
        expect(subject).to have_css('.unavailable')
      end

      it 'includes the status text' do
        expect(subject).to have_content('Not requestable')
      end
    end
  end

  describe '#aeon_reading_room_code' do
    describe 'location not in Folio::Types aeon request' do
      let(:current_request) do
        build(:request, origin: 'SPEC-COLL', origin_location: 'SPEC-STACKS', bib_data: {})
      end

      it 'returns original location code' do
        expect(aeon_reading_room_code).to eq('SPEC-COLL')
      end
    end

    describe 'ARS aeon request' do
      let(:current_request) do
        build(:request, origin: 'SAL3', origin_location: 'SAL3-PAGE-AS', bib_data: {})
      end

      it 'returns ARS location code' do
        expect(aeon_reading_room_code).to eq('ARS')
      end
    end
  end

  describe '#request_level_request_status' do
    it 'returns a message for user error codes' do
      stub_symphony_response(build(:symphony_scan_with_multiple_items))
      expect(
        request_level_request_status(create(:request_with_holdings))
      ).to include("We can't complete your request because your status is <strong>blocked</strong>")
    end

    it 'returns a message for mixed status items' do
      stub_symphony_response(build(:symphony_request_with_mixed_status))
      expect(
        request_level_request_status(create(:request_with_holdings))
      ).to include('There was a problem with one or more of your items below')
    end
  end

  describe '#queue_length_display' do
    let(:item) do
      build(:item,
            due_date: 'Jul 1, 2024',
            status: 'Checked out')
    end

    it 'returns no waitlist display when no items present in request' do
      expect(queue_length_display(nil, prefix: nil, title_only: true)).to eq 'On order | No waitlist'
    end

    it 'correctly returns a waitlist message with checked out status' do
      allow(item).to receive_messages(checked_out?: true, queue_length: 2)
      expect(queue_length_display(item, prefix: 'Item status: ',
                                        title_only: false)).to eq 'Item status: Checked out - Due Jul 1, 2024 | There is a waitlist ahead of your request'
    end
  end
end

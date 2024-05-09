# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestsHelper do
  include ApplicationHelper

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
                                        title_only: false)).to eq 'Item status: Checked out - Due Jul 1, 2024 | There is a waitlist ahead of your request' # rubocop:disable Layout/LineLength
    end
  end

  describe '#callnumber_label' do
    it 'returns "(no call number)" when the item has no call number' do
      item = build(:item, callnumber: nil)
      expect(callnumber_label(item)).to eq '(no call number)'
    end

    it 'returns "Shelved by title" when the item is shelved by title' do
      item = build(:item, effective_location: build(:location, code: 'MAR-SHELBYTITLE'))
      expect(callnumber_label(item)).to eq 'Shelved by title'
    end

    it 'returns "Shelved by Series title" when the item is shelved by series title' do
      item = build(:item, effective_location: build(:location, code: 'SCI-SHELBYSERIES'))
      expect(callnumber_label(item)).to eq 'Shelved by Series title'
    end

    it 'returns the call number when the item has a call number' do
      item = build(:item, callnumber: 'AB123')
      expect(callnumber_label(item)).to eq 'AB123'
    end
  end
end

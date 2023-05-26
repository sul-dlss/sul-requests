# frozen_string_literal: true

require 'rails_helper'

describe RequestsHelper do
  include ApplicationHelper

  describe '#select_for_pickup_libraries' do
    let(:form) { double('form') }

    before do
      allow(form).to receive_messages(object: request)
    end

    describe 'single library' do
      let(:request) { create(:request, origin: 'SAL3', origin_location: 'PAGE-MU') }

      it 'returns library text and a hidden input w/ the destination library' do
        expect(form).to receive(:hidden_field).with(:destination, value: 'MUSIC').and_return('<hidden_field>')
        markup = Capybara.string(select_for_pickup_libraries(form))
        expect(markup).to have_css('.form-group .control-label', text: 'Will be delivered to')
        expect(markup).to have_css('.form-group .input-like-text', text: 'Music Library')
        expect(markup).to have_css('hidden_field')
      end
    end

    describe 'multiple libraries' do
      let(:request) { create(:request, origin: 'SAL3', origin_location: 'PAGE-HP') }

      it 'attempts to create a select list' do
        expect(form).to receive(:select).with(any_args).and_return('<select>')
        expect(select_for_pickup_libraries(form)).to eq '<select>'
      end

      context 'with a destination' do
        let(:request) { create(:request, origin: 'SAL3', destination: 'ART', origin_location: 'PAGE-HP') }

        it 'defaults to the destination library' do
          expect(form).to receive(:select).with(anything, anything, hash_including(selected: 'ART'), anything)
            .and_return('<select>')
          expect(select_for_pickup_libraries(form)).to eq '<select>'
        end
      end
    end
  end

  describe '#label_for_pickup_libraries_dropdown' do
    it 'is "Deliver to" when if there are mutliple possiblities' do
      expect(label_for_pickup_libraries_dropdown(%w(GREEN MUSIC))).to eq 'Deliver to'
    end

    it 'is "Will be delivered to" when there is only one possibility' do
      expect(label_for_pickup_libraries_dropdown(['GREEN'])).to eq 'Will be delivered to'
    end
  end

  describe 'format date' do
    it 'formats a date' do
      expect(format_date('2015-04-23 10:12:14')).to eq '2015-04-23 10:12am'
    end
  end

  describe 'searchworks link' do
    it 'constructs a searchworks link including the passed in html_options' do
      result = '<a data-elt-opt="somebehavior" href="http://searchworks.stanford.edu/view/234">A title</a>'
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
    let(:other_item) do
      instance_double(Searchworks::HoldingItem,
                      hold?: false,
                      paged?: false,
                      home_location: 'STACKS',
                      request_status: double(errored?: false))
    end
    let(:home_location_30) do
      instance_double(Searchworks::HoldingItem,
                      hold?: false,
                      paged?: true,
                      request_status: double(errored?: false))
    end
    let(:current_location_loan) do
      instance_double(Searchworks::HoldingItem,
                      hold?: true,
                      request_status: double(errored?: false))
    end

    context 'from symphony' do
      let(:error_item) do
        instance_double(Searchworks::HoldingItem,
                        request_status: double(
                          'status',
                          errored?: true,
                          user_error_text: 'User is blocked'
                        ))
      end

      it 'returns the request status text if the item errored' do
        expect(status_text_for_item(error_item)).to eq 'User is blocked'
      end
    end

    context 'from i18n' do
      it 'returns text for page items' do
        expect(status_text_for_item(home_location_30)).to eq 'Paged'
      end

      it 'returns text for hold items' do
        expect(status_text_for_item(current_location_loan)).to eq 'Item is on-site - hold for patron'
      end

      it 'returns text for all other items' do
        expect(status_text_for_item(other_item)).to eq 'Added to pick list'
      end
    end
  end

  describe 'i18n_location_title_key' do
    let(:current_request) { double('request') }

    before { expect(helper).to receive_messages(current_request:) }

    it 'returns the current location when present' do
      allow(current_request).to receive_messages(
        holdings: [
          instance_double(Searchworks::HoldingItem, current_location_code: 'INPROCESS')
        ]
      )
      expect(helper.i18n_location_title_key).to eq 'INPROCESS'
    end

    it 'falls back to the home location in the absense of a current location' do
      allow(current_request).to receive_messages(
        origin_location: 'ON-ORDER',
        holdings: [instance_double(Searchworks::HoldingItem, current_location_code: '')]
      )
      expect(helper.i18n_location_title_key).to eq 'ON-ORDER'
    end
  end

  describe 'label_for_item_selector_holding' do
    let(:subject) { Capybara.string(label_for_item_selector_holding(holding)) }

    describe 'checked out items' do
      let(:holding) do
        instance_double(Searchworks::HoldingItem,
                        checked_out?: true, due_date: Time.zone.today)
      end

      it 'includes the unavailable class' do
        expect(subject).to have_css('.unavailable')
      end

      it 'includes the due date' do
        expect(subject).to have_content("Due #{Time.zone.today}")
      end
    end

    describe 'non checked out items' do
      let(:holding) do
        instance_double(
          Searchworks::HoldingItem,
          checked_out?: false,
          status_class: 'noncirc_page', status_text: 'In-library use only'
        )
      end

      it 'includes the status icon' do
        expect(subject).to have_css('.noncirc_page')
      end

      it 'includes the status text' do
        expect(subject).to have_content('In-library use only')
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

  describe '#new_scan_path_for_current_request' do
    it 'returns a new scan url using the parameters of the given request' do
      request = create(:request, origin: 'GREEN', origin_location: 'STACKS', item_id: '12345')
      expect(
        new_scan_path_for_current_request(request)
      ).to eq new_scan_path(origin: 'GREEN', item_id: '12345', origin_location: 'STACKS')
    end
  end
end

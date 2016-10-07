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
      it 'should return library text and a hidden input w/ the destination library' do
        expect(form).to receive(:hidden_field).with(:destination, value: 'MUSIC').and_return('<hidden_field>')
        markup = Capybara.string(select_for_pickup_libraries(form))
        expect(markup).to have_css('.form-group .control-label', text: 'Must be used in')
        expect(markup).to have_css('.form-group .input-like-text', text: 'Music Library')
        expect(markup).to have_css('hidden_field')
      end
    end
    describe 'multiple libraries' do
      let(:request) { create(:request, origin: 'SAL3', origin_location: 'PAGE-HP') }
      it 'should attempt to create a select list' do
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
    it 'should be "Deliver to" when if there are mutliple possiblities' do
      expect(label_for_pickup_libraries_dropdown(%w(GREEN MUSIC))).to eq 'Deliver to'
    end
    it 'should be "Must be used in" when there is only one possibility' do
      expect(label_for_pickup_libraries_dropdown(['GREEN'])).to eq 'Must be used in'
    end
  end
  describe 'format date' do
    it 'should format a date' do
      expect(format_date('2015-04-23 10:12:14')).to eq '2015-04-23 10:12am'
    end
  end
  describe 'searchworks link' do
    it 'should construct a searchworks link' do
      result = '<a data-behavior="truncate" href="http://searchworks.stanford.edu/view/234">A title</a>'
      expect(searchworks_link('234', 'A title')).to eq result
    end
  end
  describe 'requester info' do
    let(:webauth_user) { User.create(webauth: 'jstanford') }
    let(:non_webauth_user) { User.create(name: 'Joe', email: 'joe@xyz.com') }
    let(:library_id_user) { User.create(library_id: '123456') }
    it 'should construct requester info for webauth user' do
      expect(requester_info(webauth_user)).to eq '<a href="mailto:jstanford@stanford.edu">jstanford@stanford.edu</a>'
    end
    it 'should construct requester info for non-webauth user' do
      expect(requester_info(non_webauth_user)).to eq '<a href="mailto:joe@xyz.com">Joe (joe@xyz.com)</a>'
    end
    it 'should construct requester info for a library id user' do
      expect(requester_info(library_id_user)).to eq '123456'
    end
  end

  describe 'request_status_for_ad_hoc_item' do
    let(:request) { create(:request) }
    it 'returns the request status object for the item' do
      request_status = request_status_for_ad_hoc_item(request, 'ABC 123')
      expect(request_status).to be_a ItemStatus
      expect(request_status.send(:status_object)).to eq(
        'approved' => false,
        'approver' => nil,
        'approval_time' => nil
      )
    end
  end

  describe 'status_text_for_item' do
    let(:other_item) do
      double(
        'holding',
        home_location: 'STACKS',
        current_location: nil,
        request_status: double(errored?: false)
      )
    end
    let(:home_location_30) do
      double(
        'holding',
        home_location: 'PAGE-30',
        current_location: nil,
        request_status: double(errored?: false)
      )
    end
    let(:current_location_loan) do
      double(
        'holding',
        home_location: 'MSS-30',
        current_location: double('location', code: 'GREEN-LOAN'),
        request_status: double(errored?: false)
      )
    end

    context 'from symphony' do
      let(:error_item) do
        double(
          'error-item',
          request_status: double(
            'status',
            errored?: true,
            symphony_user_error_text: 'User is blocked'
          )
        )
      end

      it 'returns the request status text if the item errored' do
        expect(status_text_for_item(error_item)).to eq 'User is blocked'
      end
    end

    context 'from i18n' do
      it 'returns text for ad-hoc items' do
        expect(status_text_for_item('ABC-123')).to eq 'Approved for manual processing'
      end

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
    before { expect(helper).to receive_messages(current_request: current_request) }
    it 'returns the current location when present' do
      allow(current_request).to receive_messages(
        holdings: [
          double('location', current_location: double('code', code: 'INPROCESS'))
        ]
      )
      expect(helper.i18n_location_title_key).to eq 'INPROCESS'
    end

    it 'falls back to the home location in the absense of a current location' do
      allow(current_request).to receive_messages(
        origin_location: 'ON-ORDER',
        holdings: [double('location', current_location: double('code', code: ''))]
      )
      expect(helper.i18n_location_title_key).to eq 'ON-ORDER'
    end
  end

  describe 'label_for_item_selector_holding' do
    let(:subject) { Capybara.string(label_for_item_selector_holding(holding)) }

    describe 'checked out items' do
      let(:holding) do
        double('holding', current_location: double('location', code: 'CHECKEDOUT'), due_date: Time.zone.today)
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
        double(
          'holding',
          current_location: nil,
          status: double('status', availability_class: 'noncirc_page', status_text: 'In-library use only')
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

  describe '#holding_request_status' do
    describe 'processed items' do
      let(:subject) { holding_request_status(holding, create(:request)) }
      let(:holding) do
        double(
          'holding',
          barcode: '12345',
          current_location: nil,
          request_status: double('request_status', msgcode: 209)
        )
      end

      it 'has no special status text' do
        expect(subject).to be_blank
      end
    end

    describe 'items that required a hold' do
      let(:subject) { Capybara.string(holding_request_status(holding, create(:request))) }

      let(:holding) do
        double(
          'holding',
          barcode: '12345',
          current_location: nil,
          request_status: double('request_status', msgcode: '722', text: 'Error Message')
        )
      end

      it 'provides the message text to the user' do
        stub_symphony_response(build(:symphony_page_with_multiple_items))
        expect(subject).to have_css('.alert-danger', text: '(Error Message)')
      end
    end
  end
end

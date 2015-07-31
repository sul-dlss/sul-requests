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
      expect(searchworks_link('234', 'A title')).to eq '<a href="http://searchworks.stanford.edu/view/234">A title</a>'
    end
  end
  describe 'requester info' do
    let(:webauth_user) { User.create(webauth: 'jstanford') }
    let(:non_webauth_user) { User.create(name: 'Joe', email: 'joe@xyz.com') }
    it 'should construct requester info for webauth user' do
      expect(requester_info(webauth_user)).to eq '<a href="mailto:jstanford@stanford.edu">jstanford@stanford.edu</a>'
    end
    it 'should construct requester info for non-webauth user' do
      expect(requester_info(non_webauth_user)).to eq '<a href="mailto:joe@xyz.com">Joe (joe@xyz.com)</a>'
    end
  end

  describe 'request_status_for_ad_hoc_item' do
    let(:request) { create(:request) }
    it 'returns the request status object for the item' do
      request_status = request_status_for_ad_hoc_item(request, 'ABC 123')
      expect(request_status).to be_a SearchworksItem::RequestedHoldings::RequestStatus
      expect(request.request_status_data['ABC 123']).to eq(
        'approved' => false,
        'approver' => nil,
        'approval_time' => nil
      )
      expect(request_status.status_object).to eq(
        'approved' => false,
        'approver' => nil,
        'approval_time' => nil
      )
    end
  end

  describe 'status_text_for_item' do
    let(:other_item) do
      double('holding', home_location: 'STACKS', current_location: nil)
    end
    let(:home_location_30) do
      double('holding', home_location: 'PAGE-30', current_location: nil)
    end
    let(:current_location_loan) do
      double(
        'holding',
        home_location: 'STACKS',
        current_location: double('location', code: 'GREEN-LOAN')
      )
    end

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

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
        expect(form).to receive(:select).with(
          :destination,
          [['Green Library', 'GREEN'], ['Marine Biology Library (Miller)', 'HOPKINS']],
          label: 'Deliver to',
          selected: 'GREEN'
        ).and_return('<select>')
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
  describe 'todays date' do
    it 'should return todays date' do
      allow(Time).to receive(:now).and_return(Time.parse('2015-12-31'))
      expect(todays_date()).to eq '2015-12-31'
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
end

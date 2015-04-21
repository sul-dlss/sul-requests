require 'rails_helper'

describe RequestsHelper do
  include ApplicationHelper
  describe '#select_for_pickup_libraries' do
    let(:form) { double('form') }
    before do
      allow(form).to receive_messages(object: request)
    end
    describe 'single library' do
      let(:request) { Request.new(origin: 'SAL3', origin_location: 'PAGE-MU') }
      it 'should return library text and a hidden input w/ the destination library' do
        expect(form).to receive(:hidden_field).with(:destination, value: 'MUSIC').and_return('<hidden_field>')
        markup = Capybara.string(select_for_pickup_libraries(form))
        expect(markup).to have_css('.form-group .control-label', text: 'Must be used in')
        expect(markup).to have_css('.form-group .input-like-text', text: 'Music Library')
        expect(markup).to have_css('hidden_field')
      end
    end
    describe 'multiple libraries' do
      let(:request) { Request.new(origin: 'SAL3', origin_location: 'PAGE-HP') }
      it 'should attempt to create a select list' do
        expect(form).to receive(:select).with(
          :destination,
          [['Green Library', 'GREEN'], ['Marine Biology Library (Miller)', 'HOPKINS']],
          label: 'Deliver to'
        ).and_return('<select>')
        expect(select_for_pickup_libraries(form)).to eq '<select>'
      end
    end
  end
end

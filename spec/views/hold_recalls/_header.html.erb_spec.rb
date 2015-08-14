require 'rails_helper'

describe 'hold_recalls/_header.html.erb' do
  let(:current_request) { double('request') }
  before do
    allow(view).to receive_messages(current_request: current_request)
  end

  describe 'no current location' do
    before do
      allow(current_request).to receive_messages(holdings: [
        double(
          'holding',
          home_location: 'INPROCESS',
          current_location: double('location', code: '')
        )
      ])
    end
    it 'falls back to the home location' do
      render
      expect(rendered).to have_css('h1', text: 'Request in-process item')
      expect(rendered).not_to have_css('h1', text: 'checked-out')
    end
  end

  describe 'ON-ORDER' do
    before do
      allow(current_request).to receive_messages(holdings: [
        double('holding', current_location: double('location', code: 'ON-ORDER'))
      ])
    end
    it 'has the correct header' do
      render
      expect(rendered).to have_css('h1', text: 'Request on-order item')
    end
  end

  describe 'INPROCESS' do
    before do
      allow(current_request).to receive_messages(holdings: [
        double('holding', current_location: double('location', code: 'INPROCESS'))
      ])
    end
    it 'has the correct header' do
      render
      expect(rendered).to have_css('h1', text: 'Request in-process item')
    end
  end

  describe 'checked out' do
    before do
      allow(current_request).to receive_messages(holdings: [
        double('holding', current_location: double('location', code: 'CHECKEDOUT'))
      ])
    end
    it 'has the correct header' do
      render
      expect(rendered).to have_css('h1', text: 'Request checked-out item')
    end
  end

  describe 'default' do
    it 'falls back to the default title when there is no location' do
      allow(current_request).to receive_messages(holdings: [])
      render
      expect(rendered).to have_css('h1', text: 'Request item')
    end

    it 'falls back to the default title for other locations' do
      allow(current_request).to receive_messages(holdings: [
        double('holding', current_location: double('location', code: 'SOMETHING-ELSE'))
      ])
      render
      expect(rendered).to have_css('h1', text: 'Request item')
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

describe 'hold_recalls/_header.html.erb' do
  let(:origin) { 'GREEN' }
  let(:origin_location) { 'STACKS' }
  let(:holdings) { [] }
  let(:current_request) do
    double('request', origin:, origin_location:, holdings:)
  end

  before do
    allow(view).to receive_messages(current_request:)
  end

  describe 'blank current location' do
    let(:origin_location) { 'INPROCESS' }
    let(:holdings) do
      [double('holding', current_location: double('location', code: ''))]
    end

    it 'falls back to the home location' do
      render
      expect(rendered).to have_css('h1', text: 'Request in-process item')
      expect(rendered).not_to have_css('h1', text: 'checked-out')
    end
  end

  describe 'ON-ORDER' do
    let(:holdings) do
      [double('holding', current_location: double('location', code: 'ON-ORDER'))]
    end

    it 'has the correct header' do
      render
      expect(rendered).to have_css('h1', text: 'Request on-order item')
    end
  end

  describe 'INPROCESS' do
    let(:holdings) do
      [double('holding', current_location: double('location', code: 'INPROCESS'))]
    end

    it 'has the correct header' do
      render
      expect(rendered).to have_css('h1', text: 'Request in-process item')
    end
  end

  describe 'checked out' do
    let(:holdings) do
      [double('holding', current_location: double('location', code: 'CHECKEDOUT'))]
    end

    it 'has the correct header' do
      render
      expect(rendered).to have_css('h1', text: 'Request checked-out item')
    end
  end

  describe 'default' do
    describe 'when there is no location' do
      it 'falls back to the default title' do
        render
        expect(rendered).to have_css('h1', text: 'Request item')
      end
    end

    describe 'for other locations' do
      let(:holdings) do
        [double('holding', current_location: double('location', code: 'SOMETHING-ELSE'))]
      end

      it 'falls back to the default title' do
        render
        expect(rendered).to have_css('h1', text: 'Request item')
      end
    end
  end
end

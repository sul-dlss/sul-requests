# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AeonFilterable do
  let(:controller_class) do
    Class.new(ApplicationController) do
      include AeonFilterable
    end
  end

  let(:controller) { controller_class.new }
  let(:now) { Time.zone.now }

  let(:digital_request) do
    build(:aeon_request, :digitized, title: 'Digital Item', creation_date: now)
  end

  let(:reading_room_request_a) do
    build(:aeon_request, title: 'Reading Room A', creation_date: now - 1.day)
  end

  let(:reading_room_request_b) do
    build(:aeon_request, title: 'Reading Room B', creation_date: now - 2.days)
  end

  let(:requests) { [digital_request, reading_room_request_a, reading_room_request_b] }

  before do
    allow(controller).to receive(:params).and_return(ActionController::Parameters.new(filter: filter_param))
  end

  describe '#filter_aeon_requests' do
    context 'with all filter (default)' do
      let(:filter_param) { nil }

      it 'returns all requests' do
        result = controller.send(:filter_aeon_requests, requests)
        expect(result).to eq requests
      end
    end

    context 'with digitization filter' do
      let(:filter_param) { 'digitization' }

      it 'returns only digital requests' do
        result = controller.send(:filter_aeon_requests, requests)
        expect(result.map(&:title)).to eq ['Digital Item']
      end
    end

    context 'with reading_room filter' do
      let(:filter_param) { 'reading_room' }

      it 'returns only non-digital requests' do
        result = controller.send(:filter_aeon_requests, requests)
        expect(result.map(&:title)).to eq ['Reading Room A', 'Reading Room B']
      end
    end

    context 'with an invalid filter param' do
      let(:filter_param) { 'invalid' }

      it 'falls back to all filter' do
        result = controller.send(:filter_aeon_requests, requests)
        expect(result).to eq requests
      end
    end
  end

  describe '#current_aeon_filter' do
    context 'with a valid filter param' do
      let(:filter_param) { 'digitization' }

      it 'returns the filter param' do
        expect(controller.send(:current_aeon_filter)).to eq 'digitization'
      end
    end

    context 'with an invalid filter param' do
      let(:filter_param) { 'invalid' }

      it 'returns the default filter' do
        expect(controller.send(:current_aeon_filter)).to eq 'all'
      end
    end

    context 'with no filter param' do
      let(:filter_param) { nil }

      it 'returns the default filter' do
        expect(controller.send(:current_aeon_filter)).to eq 'all'
      end
    end
  end
end

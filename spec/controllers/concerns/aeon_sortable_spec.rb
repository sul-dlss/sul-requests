# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AeonSortable do
  let(:controller_class) do
    Class.new(ApplicationController) do
      include AeonSortable

      def index
        head :ok
      end
    end
  end

  let(:controller) { controller_class.new }

  let(:now) { Time.zone.now }

  let(:request_a) do
    Aeon::Request.new(
      title: 'Alpha',
      creation_date: now - 1.day,
      transaction_date: now - 3.days,
      shipping_option: 'Will Call',
      appointment: Aeon::Appointment.new(start_time: now + 1.day)
    )
  end

  let(:request_b) do
    Aeon::Request.new(
      title: 'Beta',
      creation_date: now - 2.days,
      transaction_date: now - 1.day,
      shipping_option: 'Electronic Delivery',
      photoduplication_status: 'New',
      appointment: nil
    )
  end

  let(:request_c) do
    Aeon::Request.new(
      title: 'Charlie',
      creation_date: now,
      transaction_date: now - 2.days,
      shipping_option: 'Will Call',
      appointment: Aeon::Appointment.new(start_time: now + 3.days)
    )
  end

  let(:requests) { [request_a, request_b, request_c] }

  before do
    allow(controller).to receive(:params).and_return(ActionController::Parameters.new(sort: sort_param))
  end

  describe '#sort_aeon_requests' do
    context 'with date_added sort (default)' do
      let(:sort_param) { nil }

      it 'sorts by creation_date descending' do
        result = controller.send(:sort_aeon_requests, requests)
        expect(result.map(&:title)).to eq %w[Charlie Alpha Beta]
      end
    end

    context 'with date_modified sort' do
      let(:sort_param) { 'date_modified' }

      it 'sorts by transaction_date descending' do
        result = controller.send(:sort_aeon_requests, requests)
        expect(result.map(&:title)).to eq %w[Beta Charlie Alpha]
      end
    end

    context 'with title sort' do
      let(:sort_param) { 'title' }

      it 'sorts alphabetically by title' do
        result = controller.send(:sort_aeon_requests, requests)
        expect(result.map(&:title)).to eq %w[Alpha Beta Charlie]
      end
    end

    context 'with request_type sort' do
      let(:sort_param) { 'request_type' }

      it 'sorts digital requests first, then by title' do
        result = controller.send(:sort_aeon_requests, requests)
        expect(result.map(&:title)).to eq %w[Beta Alpha Charlie]
      end
    end

    context 'with appointment_time sort' do
      let(:sort_param) { 'appointment_time' }

      it 'sorts by appointment start_time, nil appointments last' do
        result = controller.send(:sort_aeon_requests, requests)
        expect(result.map(&:title)).to eq %w[Alpha Charlie Beta]
      end
    end

    context 'with an invalid sort param' do
      let(:sort_param) { 'invalid' }

      it 'falls back to date_added sort' do
        result = controller.send(:sort_aeon_requests, requests)
        expect(result.map(&:title)).to eq %w[Charlie Alpha Beta]
      end
    end
  end

  describe '#current_aeon_sort' do
    context 'with a valid sort param' do
      let(:sort_param) { 'title' }

      it 'returns the sort param' do
        expect(controller.send(:current_aeon_sort)).to eq 'title'
      end
    end

    context 'with an invalid sort param' do
      let(:sort_param) { 'invalid' }

      it 'returns the default sort' do
        expect(controller.send(:current_aeon_sort)).to eq 'date_added'
      end
    end

    context 'with no sort param' do
      let(:sort_param) { nil }

      it 'returns the default sort' do
        expect(controller.send(:current_aeon_sort)).to eq 'date_added'
      end
    end
  end
end

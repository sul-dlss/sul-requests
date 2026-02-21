# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AeonSortable do
  let(:controller_class) do
    Class.new(ApplicationController) do
      include AeonSortable
    end
  end

  let(:controller) { controller_class.new }
  let(:now) { Time.zone.now }

  let(:request_a_with_appointment) do
    build(:aeon_request,
          title: 'Apples',
          creation_date: now - 1.day,
          transaction_date: now - 3.days,
          appointment: build(:aeon_appointment, start_time: now + 1.day))
  end

  let(:request_b_digitial) do
    build(:aeon_request, :digitized,
          title: 'Bananas',
          creation_date: now - 2.days,
          transaction_date: now - 1.day)
  end

  let(:request_c_with_appointment) do
    build(:aeon_request,
          title: 'Carrots',
          creation_date: now,
          transaction_date: now - 2.days,
          appointment: build(:aeon_appointment, start_time: now + 3.days))
  end

  let(:requests) { [request_c_with_appointment, request_a_with_appointment, request_b_digitial] }

  before do
    allow(controller).to receive(:params).and_return(ActionController::Parameters.new(sort: sort_param))
  end

  describe '#sort_aeon_requests' do
    context 'with date_added sort (default)' do
      let(:sort_param) { nil }

      it 'sorts by creation_date descending' do
        result = controller.send(:sort_aeon_requests, requests)
        expect(result.map(&:title)).to eq %w[Carrots Apples Bananas]
      end
    end

    context 'with date_modified sort' do
      let(:sort_param) { 'date_modified' }

      it 'sorts by transaction_date descending' do
        result = controller.send(:sort_aeon_requests, requests)
        expect(result.map(&:title)).to eq %w[Bananas Carrots Apples]
      end
    end

    context 'with title sort' do
      let(:sort_param) { 'title' }

      it 'sorts alphabetically by title' do
        result = controller.send(:sort_aeon_requests, requests)
        expect(result.map(&:title)).to eq %w[Apples Bananas Carrots]
      end
    end

    context 'with request_type sort' do
      let(:sort_param) { 'request_type' }

      it 'sorts digital requests first, then by title' do
        result = controller.send(:sort_aeon_requests, requests)
        expect(result.map(&:title)).to eq %w[Bananas Apples Carrots]
      end
    end

    context 'with appointment_time sort' do
      let(:sort_param) { 'appointment_time' }

      it 'sorts by appointment start_time, requests without appointments appearing last' do
        result = controller.send(:sort_aeon_requests, requests)
        expect(result.map(&:title)).to eq %w[Apples Carrots Bananas]
      end
    end

    context 'with an invalid sort param' do
      let(:sort_param) { 'invalid' }

      it 'falls back to date_added sort' do
        result = controller.send(:sort_aeon_requests, requests)
        expect(result.map(&:title)).to eq %w[Carrots Apples Bananas]
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

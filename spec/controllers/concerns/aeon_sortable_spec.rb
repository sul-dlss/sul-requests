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
  let(:kind_param) { 'submitted' }

  let(:request_a_with_appointment) do
    build(:aeon_request,
          item_title: 'Apples',
          creation_date: now - 1.day,
          transaction_date: now - 3.days,
          appointment: build(:aeon_appointment, start_time: now + 1.day))
  end

  let(:request_b_digitial) do
    build(:aeon_request, :digitized,
          item_title: 'Bananas',
          creation_date: now - 5.days,
          transaction_date: now - 4.days)
  end

  let(:request_c_with_appointment) do
    build(:aeon_request,
          item_title: 'Carrots',
          creation_date: now,
          transaction_date: now - 2.days,
          appointment: build(:aeon_appointment, start_time: now + 3.days))
  end

  let(:requests) do
    Aeon::RequestFinders.new([request_c_with_appointment, request_a_with_appointment, request_b_digitial])
  end

  before do
    allow(controller).to receive(:params).and_return(ActionController::Parameters.new(sort: sort_param, kind: kind_param))
  end

  describe '#sort_aeon_requests' do
    context 'with default sort (default)' do
      let(:sort_param) { nil }

      it 'sorts by transaction_date descending' do
        result = controller.send(:sort_aeon_requests, requests)
        expect(result.map(&:title)).to eq %w[Apples Carrots Bananas]
      end
    end

    context 'with title sort' do
      let(:sort_param) { 'title' }

      it 'sorts alphabetically by title' do
        result = controller.send(:sort_aeon_requests, requests)
        expect(result.map(&:title)).to eq %w[Apples Bananas Carrots]
      end
    end

    context 'with date sort' do
      let(:sort_param) { 'date' }

      it 'sorts by request created/modified time' do
        result = controller.send(:sort_aeon_requests, requests)
        expect(result.map(&:title)).to eq %w[Carrots Apples Bananas]
      end
    end

    context 'with an invalid sort param' do
      let(:sort_param) { 'invalid' }

      it 'falls back to default sort' do
        result = controller.send(:sort_aeon_requests, requests)
        expect(result.map(&:title)).to eq %w[Apples Carrots Bananas]
      end
    end

    context 'with cancelled request type' do
      let(:kind_param) { 'cancelled' }
      let(:sort_param) { 'invalid' }

      it 'falls back to default sort date' do
        result = controller.send(:sort_aeon_requests, requests)
        expect(result.map(&:title)).to eq %w[Carrots Apples Bananas]
      end
    end

    context 'with saved_for_later request type' do
      let(:kind_param) { 'saved_for_later' }
      let(:sort_param) { 'invalid' }

      it 'falls back to default sort title' do
        result = controller.send(:sort_aeon_requests, requests)
        expect(result.map(&:title)).to eq %w[Apples Bananas Carrots]
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
        expect(controller.send(:current_aeon_sort)).to eq 'request_timing'
      end
    end

    context 'with no sort param' do
      let(:sort_param) { nil }

      it 'returns the default sort' do
        expect(controller.send(:current_aeon_sort)).to eq 'request_timing'
      end
    end

    context 'with cancelled request type' do
      let(:kind_param) { 'cancelled' }
      let(:sort_param) { nil }

      it 'falls back to default sort date' do
        expect(controller.send(:current_aeon_sort)).to eq 'date'
      end
    end

    context 'with saved_for_later request type' do
      let(:kind_param) { 'saved_for_later' }
      let(:sort_param) { nil }

      it 'falls back to default sort title' do
        expect(controller.send(:current_aeon_sort)).to eq 'title'
      end
    end
  end

  describe '#available_aeon_sort_options' do
    let(:filterable_controller_class) do
      Class.new(ApplicationController) do
        include AeonFilterable
        include AeonSortable
      end
    end

    let(:filterable_controller) { filterable_controller_class.new }
    let(:sort_param) { nil }
    let(:filter_param) { nil }

    before do
      allow(filterable_controller).to receive(:params)
        .and_return(ActionController::Parameters.new(sort: sort_param, filter: filter_param, kind: kind_param))
    end

    context 'without a filter' do
      it 'includes all sort options' do
        expect(filterable_controller.send(:available_aeon_sort_options).keys)
          .to eq %w[title date request_timing]
      end
    end

    context 'with the digitization filter' do
      let(:filter_param) { 'digitization' }

      it 'excludes request_type and appointment_time' do
        expect(filterable_controller.send(:available_aeon_sort_options).keys)
          .to eq %w[title date request_timing]
      end
    end

    context 'with the reading_room filter' do
      let(:filter_param) { 'reading_room' }

      it 'excludes request_type but includes appointment_time' do
        expect(filterable_controller.send(:available_aeon_sort_options).keys)
          .to eq %w[title date request_timing]
      end
    end

    context 'when sort param is unavailable for current filter' do
      let(:sort_param) { 'appointment_time' }
      let(:filter_param) { 'digitization' }

      it 'falls back to default sort' do
        expect(filterable_controller.send(:current_aeon_sort)).to eq 'request_timing'
      end
    end

    context 'with cancelled request type' do
      let(:kind_param) { 'cancelled' }

      it 'does not include request_timing' do
        expect(filterable_controller.send(:available_aeon_sort_options).keys)
          .to eq %w[title date]
      end
    end

    context 'with saved_for_later request type' do
      let(:kind_param) { 'saved_for_later' }

      it 'does not include request_timing' do
        expect(filterable_controller.send(:available_aeon_sort_options).keys)
          .to eq %w[title date]
      end
    end
  end
end

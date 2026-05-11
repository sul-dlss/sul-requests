# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestsLocationHelper do
  let(:patron) do
    build(:undergraduate_patron)
  end

  let(:default_service_points) do
    Folio::ServicePoint.default_service_points
  end

  describe '#request_location_options' do
    context 'with a restricted pickup service point' do
      let(:request) do
        instance_double(Folio::Request, service_point_id: '77cd12ac-2de8-4d13-99a0-f6b3b4f4bdca')
      end

      before do
        allow(request).to receive(:restricted_pickup_service_points).and_return([Folio::ServicePoint.new(
          code: 'ART',
          id: '77cd12ac-2de8-4d13-99a0-f6b3b4f4bdca',
          name: 'Art & Architecture (Bowes)',
          pickup_location: true,
          is_default_pickup: false,
          is_default_for_campus: false
        )])
      end

      it 'only allows the restricted service point as an option' do
        options = helper.request_location_options(request, patron)
        expect(options).to have_css 'option', count: 1
      end

      it 'creates option with correct value and text' do
        options = helper.request_location_options(request, patron)
        expect(options).to have_css 'option[value="77cd12ac-2de8-4d13-99a0-f6b3b4f4bdca"]',
                                    text: 'Art & Architecture (Bowes)'
      end
    end

    context 'with a patron that is ineligible for the restricted service point' do
      let(:patron) { build(:purchased_patron) }
      let(:request) do
        instance_double(Folio::Request, service_point_id: '77cd12ac-2de8-4d13-99a0-f6b3b4f4bdca')
      end

      before do
        allow(request).to receive(:restricted_pickup_service_points).and_return([Folio::ServicePoint.new(
          id: '0483c7bd-8e95-4c7b-9704-484b01879b02',
          code: 'LANE-DESK',
          name: 'Lane Medical Library',
          pickup_location: true,
          is_default_pickup: false,
          is_default_for_campus: false
        )])
      end

      it 'does not include the restricted service point in the options list' do
        options = helper.request_location_options(request, patron)
        expect(options).to have_css 'option', count: 0
      end
    end

    context 'with an otherwise ineligible patron with a request is already set to a restricted service point' do
      let(:patron) do
        build(:purchased_patron)
      end

      let(:request) do
        instance_double(Folio::Request, service_point_id: '0483c7bd-8e95-4c7b-9704-484b01879b02')
      end

      before do
        allow(request).to receive(:restricted_pickup_service_points).and_return([Folio::ServicePoint.new(
          id: '0483c7bd-8e95-4c7b-9704-484b01879b02',
          code: 'LANE-DESK',
          name: 'Lane Medical Library',
          pickup_location: true,
          is_default_pickup: false,
          is_default_for_campus: false
        )])
      end

      it 'includes the restricted service point in the options list' do
        options = helper.request_location_options(request, patron)
        expect(options).to have_css 'option', count: 1
      end
    end

    context 'with a patron that is ineligible for some service point' do
      let(:request) do
        instance_double(Folio::Request, service_point_id: '77cd12ac-2de8-4d13-99a0-f6b3b4f4bdca')
      end

      before do
        allow(patron).to receive(:patron_group_name).and_return('sul-purchased')
        allow(request).to receive(:restricted_pickup_service_points).and_return(nil)
      end

      it 'does not include the restricted service point in the options list' do
        options = helper.request_location_options(request, patron)
        expect(options).not_to include('Lane Medical Library')
      end
    end

    context 'with a non-restricted pickup service point' do
      let(:request) do
        instance_double(Folio::Request, service_point_id: 'a5dbb3dc-84f8-4eb3-8bfe-c61f74a9e92d')
      end

      before do
        allow(Folio::Types).to receive_messages(service_points: Folio::TypeStore.new(
          Folio::ServicePoint, [instance_double(Folio::ServicePoint,
                                                code: 'GREEN-LOAN',
                                                id: 'a5dbb3dc-84f8-4eb3-8bfe-c61f74a9e92d',
                                                is_default_for_campus: 'SUL',
                                                is_default_pickup: true,
                                                name: 'Green Library',
                                                patron_unpermitted_for_pickup?: false,
                                                pickup_location: true)]
        ))
        allow(request).to receive(:restricted_pickup_service_points).and_return(nil)
      end

      it 'puts all the defaults into the options list' do
        options = helper.request_location_options(request, patron)
        expect(options).to have_css 'option', count: default_service_points.count
      end

      it 'pre-selects the origin service point of the request' do
        options = helper.request_location_options(request, patron)
        expect(options).to have_css("option[selected='selected'][value='a5dbb3dc-84f8-4eb3-8bfe-c61f74a9e92d']",
                                    text: 'Green Library')
      end
    end

    context 'with a non-default origin pickup service point that is pickup_location=true' do
      let(:request) do
        instance_double(Folio::Request, service_point_id: 'faa81922-3da8-4086-a7fa-977d7d3e7977')
      end

      before do
        allow(Folio::Types).to receive_messages(service_points: Folio::TypeStore.new(
          Folio::ServicePoint, [instance_double(Folio::ServicePoint,
                                                code: 'ARS',
                                                id: 'faa81922-3da8-4086-a7fa-977d7d3e7977',
                                                is_default_for_campus: nil,
                                                is_default_pickup: false,
                                                name: 'Archive of Recorded Sound',
                                                unpermitted_pickup_groups: [],
                                                pickup_location: true,
                                                patron_unpermitted_for_pickup?: false)]
        ))
        allow(request).to receive(:restricted_pickup_service_points).and_return(nil)
      end

      it 'adds the origin service point to the default options list if it is a pickup location' do
        options = helper.request_location_options(request, patron)
        expect(options).to have_css 'option', count: default_service_points.count + 1
      end

      it 'pre-selects the origin service point of the request' do
        options = helper.request_location_options(request, patron)
        expect(options).to have_css("option[selected='selected'][value='faa81922-3da8-4086-a7fa-977d7d3e7977']",
                                    text: 'Archive of Recorded Sound')
      end
    end

    context 'with a non-default origin pickup service point that is pickup_location=false' do
      let(:request) do
        instance_double(Folio::Request, service_point_id: '8bb5d494-263f-42f0-9a9f-70451530d8a3')
      end

      before do
        allow(Folio::Types).to receive_messages(service_points: Folio::TypeStore.new(
          Folio::ServicePoint, [instance_double(Folio::ServicePoint,
                                                code: 'CLASSICS',
                                                id: '8bb5d494-263f-42f0-9a9f-70451530d8a3',
                                                is_default_for_campus: nil,
                                                is_default_pickup: false,
                                                name: 'Classics Library',
                                                pickup_location: false)]
        ))
        allow(request).to receive(:restricted_pickup_service_points).and_return(nil)
      end

      it 'does not add the origin service point to the default options list' do
        options = helper.request_location_options(request, patron)
        expect(options).to have_no_css("option[value='8bb5d494-263f-42f0-9a9f-70451530d8a3']",
                                       text: 'Classics Library')
      end

      it 'keeps the original default options list' do
        options = helper.request_location_options(request, patron)
        expect(options).to have_css 'option', count: default_service_points.count
      end
    end
  end
end

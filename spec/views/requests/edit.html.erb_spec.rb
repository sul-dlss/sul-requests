# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'requests/edit' do
  let(:request_attributes) { {} }
  let(:mock_request) do
    instance_double(
      Folio::Request,
      title: 'Request Title',
      key: 'abc123',
      fill_by_date: nil,
      service_point_id: 'a5dbb3dc-84f8-4eb3-8bfe-c61f74a9e92d',
      restricted_pickup_service_points: [],
      **request_attributes
    )
  end

  let(:patron_or_group) { instance_double(Folio::Patron, patron_group_name: nil) }

  before do
    without_partial_double_verification do
      allow(view).to receive_messages(patron_or_group:)
    end

    assign(:request, mock_request)
    render
  end

  context 'when the request has a fill_by_date' do
    let(:request_attributes) { { fill_by_date: Time.zone.parse('2019-01-01') } }

    it 'has a date selector to update the fill_by_date' do
      expect(rendered).to have_field('not_needed_after', type: 'date')
    end
  end

  context 'when the request has no fill_by_date' do
    it 'does not have a date selector to update the fill_by_date' do
      expect(rendered).to have_no_field('not_needed_after', type: 'date')
    end
  end
end

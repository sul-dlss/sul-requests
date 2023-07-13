# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/admin').to route_to('admin#index')
    end

    it 'routes to #show' do
      expect(get: '/admin/SPEC-COLL').to route_to('admin#show', id: 'SPEC-COLL')
    end

    it 'routes to #holdings' do
      expect(get: '/admin/1/holdings').to route_to('admin#holdings', id: '1')
    end
  end
end

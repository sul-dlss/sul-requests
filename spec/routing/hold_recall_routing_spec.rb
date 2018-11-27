# frozen_string_literal: true

require 'rails_helper'

describe HoldRecallsController, type: :routing do
  it 'routes to #new' do
    expect(get: '/hold_recalls/new').to route_to('hold_recalls#new')
  end

  it 'routes to #edit' do
    expect(get: '/hold_recalls/1/edit').to route_to('hold_recalls#edit', id: '1')
  end

  it 'routes to #success' do
    expect(get: '/hold_recalls/1/success').to route_to('hold_recalls#success', id: '1')
  end

  it 'routes to #status' do
    expect(get: '/hold_recalls/1/status').to route_to('hold_recalls#status', id: '1')
  end

  describe 'create' do
    it 'routes to #create via post' do
      expect(post: '/hold_recalls').to route_to('hold_recalls#create')
    end

    it 'routes to #create via get' do
      expect(get: '/hold_recalls/create').to route_to('hold_recalls#create')
    end
  end
end

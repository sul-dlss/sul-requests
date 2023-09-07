# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'mediated_pages/_header.html.erb' do
  let(:holdings) { [] }
  let(:current_request) { instance_double(Request, location:, holdings:) }

  before do
    allow(view).to receive_messages(current_request:)
  end

  describe 'library level titles' do
    let(:location) { 'MAR-STACKS' }

    it 'are returned when present' do
      render
      expect(rendered).to have_css('h1', text: 'Request delivery to campus library')
    end
  end

  describe 'location level titles' do
    let(:location) { 'SAL3-PAGE-MP' }

    it 'are returned when present' do
      render
      expect(rendered).to have_css('h1', text: 'Request delivery to campus library')
    end
  end

  describe 'default' do
    let(:location) { 'GRE-STACKS' }

    it 'falls back to the default title when there is no location' do
      render
      expect(rendered).to have_css('h1', text: 'Request on-site access')
    end
  end
end

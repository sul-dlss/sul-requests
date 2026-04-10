# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Requesting an item from an EAD' do
  context 'when the redesign feature flag is disabled' do
    it 'redirects the user to Aeon' do
      begin
        visit new_archives_request_path(value: 'http://example.com/ead.xml')
      rescue ActionController::RoutingError
        # Capybara can't find the external Aeon route.
      end

      expect(page.current_url).to start_with(Settings.aeon_archives_url)
      expect(page.current_url).to include('Value=http://example.com/ead.xml')
    end
  end
end

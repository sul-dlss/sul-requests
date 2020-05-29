# frozen_string_literal: true

require 'rails_helper'

describe 'Eligibility Confirmation' do
  before do
    expect(Settings.features).to receive(:confirm_eligibility).and_return(true)
  end

  context 'for page requests' do
    it 'shows an eligibility confiration overlay that can be cleared to reveal the form' do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')

      expect(page).to have_css('#new_request', visible: false)
      expect(page).to have_css('#eligibility-confirm-overlay', visible: true)

      click_button 'Continue'

      expect(page).to have_css('#eligibility-confirm-overlay', visible: false)
      expect(page).to have_css('#new_request', visible: true)
    end
  end
end

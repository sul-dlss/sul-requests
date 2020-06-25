# frozen_string_literal: true

require 'rails_helper'

describe 'Eligibility Confirmation', js: true do
  before do
    expect(Settings.features).to receive(:confirm_eligibility).and_return(true)
  end

  context 'for page requests' do
    it 'shows an eligibility confiration overlay that can be cleared to reveal the form' do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')

      expect(page).to have_css('#new_request', obscured: true)
      expect(page).to have_css('#eligibility-confirm-overlay', visible: :visible)

      click_button 'Continue'

      expect(page).to have_css('#eligibility-confirm-overlay', visible: :hidden)
      expect(page).to have_css('#new_request', obscured: false)
    end
  end

  context 'for mediated page requests for SPEC' do
    it 'shows an eligibility confiration overlay that can be cleared to reveal the form' do
      visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'RARE-BOOKS')

      expect(page).to have_css('#new_request', obscured: true)
      expect(page).to have_css('#eligibility-confirm-overlay', visible: :visible)

      click_button 'Continue'
      # This isn't happening in practice, but under test we have double overlays
      page.find('button', text: /I will visit in person/).click

      expect(page).to have_css('#eligibility-confirm-overlay', visible: :hidden)
      expect(page).to have_css('#new_request', obscured: false)
    end
  end

  context 'for mediated page requests for RUMSEYMAP' do
    it 'shows an eligibility confiration overlay that can be cleared to reveal the form' do
      visit new_mediated_page_path(item_id: '1234', origin: 'RUMSEYMAP', origin_location: 'STACKS')

      expect(page).to have_css('#new_request', obscured: true)
      expect(page).to have_css('#eligibility-confirm-overlay', visible: :visible)

      click_button 'Continue'
      # This isn't happening in practice, but under test we have double overlays
      page.find('button', text: /I will visit in person/).click

      expect(page).to have_css('#eligibility-confirm-overlay', visible: :hidden)
      expect(page).to have_css('#new_request', obscured: false)
    end
  end

  context 'for mediated page requests for ART locked stacks' do
    it 'shows an eligibility confiration overlay that can be cleared to reveal the form' do
      visit new_mediated_page_path(item_id: '1234', origin: 'ART', origin_location: 'ARTLCKL')

      expect(page).to have_css('#new_request', obscured: true)
      expect(page).to have_css('#eligibility-confirm-overlay', visible: :visible)

      click_button 'Continue'
      # This isn't happening in practice, but under test we have double overlays
      page.find('button', text: /I will visit in person/).click

      expect(page).to have_css('#eligibility-confirm-overlay', visible: :hidden)
      expect(page).to have_css('#new_request', obscured: false)
    end
  end
end

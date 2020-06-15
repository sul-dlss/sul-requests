# frozen_string_literal: true

require 'rails_helper'

describe 'Eligibility Confirmation' do
  before do
    expect(Settings.features).to receive(:confirm_eligibility).and_return(true)
  end

  context 'for page requests' do
    it 'shows an eligibility confiration overlay that can be cleared to reveal the form' do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')

      expect(page).to have_css('#new_request', visible: :all)
      expect(page).to have_css('#eligibility-confirm-overlay', visible: :visible)

      click_button 'Continue'

      expect(page).to have_css('#eligibility-confirm-overlay', visible: :all)
      expect(page).to have_css('#new_request', visible: :visible)
    end
  end

  context 'for mediated page requests' do
    it 'shows an eligibility confiration overlay that can be cleared to reveal the form' do
      visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'RARE-BOOKS')

      expect(page).to have_css('#new_request', visible: :all)
      expect(page).to have_css('#eligibility-confirm-overlay', visible: :visible)

      click_button 'Continue'

      expect(page).to have_css('#eligibility-confirm-overlay', visible: :all)
      expect(page).to have_css('#new_request', visible: :visible)
    end
  end
end

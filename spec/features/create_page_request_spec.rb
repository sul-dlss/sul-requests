require 'rails_helper'

describe 'Creating a page request' do
  describe 'by an anonmyous user' do
    it 'should be possible if a name and email is filled out', js: true do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')
      click_link "I don't have a SUNet ID"

      fill_in 'Name', with: 'Jane Stanford'
      fill_in 'Email', with: 'jstanford@stanford.edu'

      click_button 'Send request'

      expect(page).to have_css('.alert-success', text: /Request was successfully created/)
    end
  end
  describe 'by a webauth user' do
    before { stub_current_user }
    it 'should be possible without filling in any user information' do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')
      click_button 'Send request'

      expect(page).to have_css('.alert-success', text: /Request was successfully created/)
    end
  end
end

require 'rails_helper'

describe 'Creating a page request' do
  describe 'by an anonmyous user' do
    it 'should be possible if a name and email is filled out', js: true do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')
      click_link "I don't have a SUNet ID"

      fill_in 'Name', with: 'Jane Stanford'
      fill_in 'Email', with: 'jstanford@stanford.edu'

      click_button 'Send request'

      expect(page).to have_css('h1#dialogTitle', text: 'Request complete')
    end
  end
  describe 'by a webauth user' do
    before { stub_current_user }
    it 'should be possible without filling in any user information' do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')
      click_button 'Send request'

      expect(current_url).to eq successfull_page_url(Page.last)
      expect(page).to have_css('h1#dialogTitle', text: 'Request complete')
    end
  end
  describe 'comments' do
    before { stub_current_user }
    it 'should have a comments field for commentable libraries' do
      visit new_page_path(item_id: '1234', origin: 'SAL-NEWARK', origin_location: 'STACKS')

      comment = '1989, Mar: Le Monde'
      fill_in 'Comments', with: comment

      click_button 'Send request'

      expect(page).to have_css('h1#dialogTitle', text: 'Request complete')

      expect(Page.last.data['comments']).to eq comment
    end
  end
end

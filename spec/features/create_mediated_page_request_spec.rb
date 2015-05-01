require 'rails_helper'

describe 'Creating a mediated page request' do
  let(:user) { create(:webauth_user) }
  describe 'by an anonmyous user' do
    it 'should be possible if a name and email is filled out', js: true do
      visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')
      click_link "I don't have a SUNet ID"

      fill_in 'Name', with: 'Jane Stanford'
      fill_in 'Email', with: 'jstanford@stanford.edu'

      click_button 'Send request'

      expect(page).to have_css('h1#dialogTitle', text: 'Request complete')
    end
  end
  describe 'by a webauth user' do
    before { stub_current_user(user) }
    it 'should be possible without filling in any user information' do
      visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')
      click_button 'Send request'

      expect(current_url).to eq successfull_mediated_page_url(MediatedPage.last)
      expect(page).to have_css('h1#dialogTitle', text: 'Request complete')
    end
  end
  describe 'comments' do
    before { stub_current_user(user) }
    it 'should have a comments field for commentable libraries' do
      visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')

      comment = '1989, Mar: Le Monde'
      fill_in 'Comments', with: comment

      click_button 'Send request'

      expect(page).to have_css('h1#dialogTitle', text: 'Request complete')

      expect(MediatedPage.last.data['comments']).to eq comment
    end
    it 'should not include a comments for requests that do not get them' do
      visit new_mediated_page_path(item_id: '1234', origin: 'HOOVER', origin_location: 'STACKS-30')

      expect(page).to_not have_field('Comments')
    end
  end
end

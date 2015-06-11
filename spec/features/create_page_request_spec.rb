require 'rails_helper'

describe 'Creating a page request' do
  let(:user) { create(:webauth_user) }
  describe 'item information' do
    it 'should display the items title' do
      visit new_page_path(item_id: '2824966', origin: 'GREEN', origin_location: 'STACKS')
    end
  end
  describe 'by an anonmyous user' do
    it 'should be possible if a name and email is filled out', js: true do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')
      click_link "I don't have a SUNet ID"

      expect(page).to have_css('input#request_user_attributes_library_id')
      expect(page.evaluate_script('document.activeElement.id')).to eq 'request_user_attributes_library_id'

      fill_in 'Name', with: 'Jane Stanford'
      fill_in 'Email', with: 'jstanford@stanford.edu'

      click_button 'Send request'

      expect(page).to have_css('h1#dialogTitle', text: 'Request complete')
    end

    it 'should be possible if a library ID is filled out', js: true do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')
      click_link "I don't have a SUNet ID"

      expect(page).to have_css('input#request_user_attributes_library_id')
      expect(page.evaluate_script('document.activeElement.id')).to eq 'request_user_attributes_library_id'

      fill_in 'Library ID', with: '123456'

      click_button 'Send request'

      expect(Page.last.user).to eq User.last
      expect(User.last.library_id).to eq '123456'
      expect(page).to have_css('h1#dialogTitle', text: 'Request complete')
    end
  end
  describe 'by a webauth user' do
    before { stub_current_user(user) }
    it 'should be possible without filling in any user information' do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')
      click_button 'Send request'

      expect(current_url).to eq successful_page_url(Page.last)
      expect(page).to have_css('h1#dialogTitle', text: 'Request complete')
    end
  end
  describe 'selecting barcodes' do
    before do
      stub_current_user(user)
      stub_searchworks_api_json(build(:multiple_holdings))
    end
    it 'should persist to the database' do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')

      within('#item-selector') do
        check('ABC 123')
        check('ABC 321')
      end

      click_button 'Send request'

      expect(page).to have_css('h1#dialogTitle', text: 'Request complete')

      expect(Page.last.barcodes).to eq(%w(3610512345678 3610587654321))
    end
  end

  describe 'item commentable' do
    before do
      stub_current_user(user)
      stub_searchworks_api_json(build(:sal_newark_holding))
    end

    it 'displays the comment field and stores the data' do
      visit new_page_path(item_id: '1234', origin: 'SAL-NEWARK', origin_location: 'STACKS')

      expect(page).to have_css('textarea#request_item_comment')

      fill_in 'request_item_comment', with: 'Volume 1-3'

      click_button 'Send request'

      expect(Page.last.item_comment).to eq 'Volume 1-3'
    end
  end
end

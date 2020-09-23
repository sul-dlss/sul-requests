# frozen_string_literal: true

require 'rails_helper'

describe 'Creating a page request' do
  let(:user) { create(:webauth_user) }

  describe 'item information' do
    it 'displays the items title' do
      visit new_page_path(item_id: '2824966', origin: 'GREEN', origin_location: 'STACKS')
    end
  end

  pending 'by an anonmyous user' do
    before { stub_searchworks_api_json(build(:single_holding)) }

    it 'is possible if a name and email is filled out', js: true do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')

      click_link "I don't have a SUNet ID"

      expect(page).to have_css('input#request_user_attributes_library_id')
      expect(page.evaluate_script('document.activeElement.id')).to eq 'request_user_attributes_library_id'

      fill_in 'Name', with: 'Jane Stanford'
      fill_in 'Email', with: 'jstanford@stanford.edu'

      click_button 'Send request'

      expect_to_be_on_success_page
    end

    it 'retrieves users by both library ID and email if both a provided by the user', js: true do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')
      click_link "I don't have a SUNet ID"

      expect(page).to have_css('input#request_user_attributes_library_id')
      expect(page).to have_css('input#request_user_attributes_email')
      expect(page.evaluate_script('document.activeElement.id')).to eq 'request_user_attributes_library_id'

      tcramer1 = User.create(library_id: '1011', email: 'tcramer1@stanford.edu')
      expect(User.where(library_id: '1011', email: 'tcramer1@stanford.edu').size).to eq(1)

      fill_in 'Library ID', with: '123456'
      fill_in 'Name', with: 'Tim Cramer'
      fill_in 'Email', with: 'tcramer1@stanford.edu'

      click_button 'Send request'

      expect(Page.last.user).to eq User.last

      # Verify that the old record was not overwritten when the new request was created
      expect(User.where(library_id: '1011', email: 'tcramer1@stanford.edu').size).to eq(1)
      expect_to_be_on_success_page

      tcramer1.destroy
    end
  end

  describe 'by a webauth user' do
    before { stub_current_user(user) }

    it 'is possible without filling in any user information' do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')
      first(:button, 'Send request').click

      expect(current_url).to eq successful_page_url(Page.last)
      expect_to_be_on_success_page
    end
  end

  describe 'by a user who sponsors a proxy group' do
    before do
      stub_current_user(user)
      allow(user).to receive(:sponsor?).and_return(true)
      stub_symphony_response(build(:symphony_page_with_single_item))
    end

    it 'allows the user to share with their proxy group' do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')
      first(:button, 'Send request').click

      expect(page).to have_css('h1#dialogTitle', text: 'Share with your proxy group?')
      click_button 'Yes, share with my group.'

      expect(current_url).to eq successful_page_url(Page.last)
      expect_to_be_on_success_page
      expect(Page.last).to be_proxy
    end

    it 'allows the user to keep the request private' do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')
      first(:button, 'Send request').click

      expect(page).to have_css('h1#dialogTitle', text: 'Share with your proxy group?')
      click_button 'No, just me.'

      expect(current_url).to eq successful_page_url(Page.last)
      expect_to_be_on_success_page
      expect(page).to have_content(
        'We\'ll send you an email at some-webauth-user@stanford.edu when processing is complete.'
      )
    end
  end

  describe 'selecting barcodes' do
    before do
      stub_current_user(user)
      stub_searchworks_api_json(build(:multiple_holdings))
    end

    it 'persists to the database' do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')

      within('#item-selector') do
        check('ABC 123')
        check('ABC 321')
      end

      first(:button, 'Send request').click

      expect_to_be_on_success_page

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

      fill_in 'Volumes/issues', with: 'Volume 1-3'

      first(:button, 'Send request').click

      expect(Page.last.item_comment).to eq 'Volume 1-3'
    end
  end

  describe 'destination and needed date highlight section' do
    it 'is included' do
      visit new_page_path(item_id: '1234', origin: 'SAL-NEWARK', origin_location: 'STACKS')

      expect(page).to have_css('.alert-warning.destination-note-callout')
    end
  end
end

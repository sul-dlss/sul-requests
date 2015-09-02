require 'rails_helper'

describe 'Creating a hold recall request' do
  let(:user) { create(:webauth_user) }
  describe 'by an anonmyous user' do
    it 'should be possible if a library id is filled out', js: true do
      visit new_hold_recall_path(
        item_id: '1234',
        barcode: '3610512345',
        origin: 'GREEN',
        origin_location: 'STACKS'
      )
      click_link "I don't have a SUNet ID"

      fill_in 'Library ID', with: '123456'

      click_button 'Send request'

      expect(HoldRecall.last.user).to eq User.last
      expect(User.last.library_id).to eq '123456'
      expect(page).to have_css('h1#dialogTitle', text: 'Request complete')
    end
  end

  describe 'by a webauth user' do
    before { stub_current_user(user) }

    it 'should be possible without filling in any user information' do
      visit new_hold_recall_path(item_id: '1234', barcode: '3610512345', origin: 'GREEN', origin_location: 'STACKS')
      first(:button, 'Send request').click

      expect(current_url).to eq successful_hold_recall_url(HoldRecall.last)
      expect(page).to have_css('h1#dialogTitle', text: 'Request complete')
    end

    it 'should store barcode in the url in the barcodes array' do
      stub_searchworks_api_json(build(:sal3_holdings))
      visit new_hold_recall_path(item_id: '1234', barcode: '12345678', origin: 'SAL3', origin_location: 'STACKS')
      first(:button, 'Send request').click

      expect(HoldRecall.last.barcodes).to eq ['12345678']
    end
  end
end

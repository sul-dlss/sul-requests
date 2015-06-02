require 'rails_helper'

describe 'Send Request Buttons' do
  before { stub_searchworks_api_json(build(:single_holding)) }
  describe 'by anonymous user' do
    it 'should be possible to toggle between login and name-email form', js: true do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')
      click_link 'I don\'t have a SUNet ID'

      expect(page).to have_field('Name', type: 'text')
      expect(page).to have_field('Email', type: 'email')
      expect(page).to have_css('a', text: '‹ Go back (show the login option)')

      click_link '‹ Go back (show the login option)'
      expect(page).to have_css('a', text: 'I don\'t have a SUNet ID')
    end
  end

  describe 'Scans' do
    before do
      stub_searchworks_api_json(build(:sal3_holdings))
      visit new_scan_path(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS')
    end
    it 'only allows to send request via WebAuth login' do
      expect(page).to have_css('button', text: /Send request.*login with SUNet ID/)
      expect(page).not_to have_css('a', text: 'I don\'t have a SUNet ID')
    end
    it 'has a link to request the physical item' do
      expect(page).to have_css('a', text: 'Request the physical item')
    end
  end

  describe 'Mediated Pages' do
    describe 'for non-HOPKINS libraries' do
      it 'allows users to submit without a SUNet ID' do
        visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')
        expect(page).to have_css('a', text: 'I don\'t have a SUNet ID')
      end
    end

    describe 'for HOPKINS' do
      it 'only allows to send request via WebAuth login' do
        visit new_mediated_page_path(item_id: '1234', origin: 'HOPKINS', origin_location: 'STACKS')
        expect(page).to have_css('button', text: /Send request.*login with SUNet ID/)
        expect(page).not_to have_css('a', text: 'I don\'t have a SUNet ID')
      end
    end
  end
end

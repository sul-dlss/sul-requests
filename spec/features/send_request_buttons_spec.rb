# frozen_string_literal: true

require 'rails_helper'

describe 'Send Request Buttons' do
  before { stub_searchworks_api_json(build(:single_holding)) }

  describe 'as a Stanford user', js: true do
    before { stub_current_user(create(:webauth_user)) }

    it 'allows submit' do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')

      click_button 'Send request'

      expect_to_be_on_success_page
    end
  end

  # TODO: COVID-19
  pending 'by anonymous user', js: true do
    it 'is possible to toggle between login and name-email form' do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')
      click_link 'I don\'t have a SUNet ID'

      expect(page).to have_field('Name', type: 'text')
      expect(page).to have_field('Email', type: 'email')
      expect(page).to have_css('a', text: '‹ Go back (show the login option)')

      click_link '‹ Go back (show the login option)'
      expect(page).to have_css('a', text: 'I don\'t have a SUNet ID')
    end

    it 'disables the submit button (and adds a tooltip) when additional user validation is needed' do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')
      click_link 'I don\'t have a SUNet ID'

      expect(page).to have_field('Library ID', type: 'text')
      expect(page).to have_field('Name', type: 'text')
      expect(page).to have_field('Email', type: 'email')

      expect(page).to have_css('input[value="Send request"][disabled].disabled')

      fill_in 'Library ID', with: '12345'
      expect(page).to have_css('input[value="Send request"].disabled')

      fill_in 'Library ID', with: ''
      expect(page).to have_css('input[value="Send request"].disabled')

      fill_in 'Name', with: 'Jane Stanford'
      expect(page).to have_css('input[value="Send request"].disabled')
      fill_in 'Email', with: 'jstanford@stanford.edu'
      expect(page).not_to have_css('input[value="Send request"].disabled')
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

    pending 'has a link to request the physical item' do
      expect(page).to have_css('a', text: 'Request the physical item')
    end
  end

  describe 'HoldRecall', js: true do
    before do
      visit new_hold_recall_path(item_id: '1234', barcode: '3610512345', origin: 'GREEN', origin_location: 'STACKS')
    end

    it 'allows to send requests via SUNet ID' do
      expect(page).to have_css('button', text: /Send request.*login with SUNet ID/m)
    end

    # TODO: COVID-19
    pending 'allows to send requests via LibraryID' do
      click_link 'I don\'t have a SUNet ID'
      expect(page).to have_field('Library ID', type: 'text')
    end

    # TODO: COVID-19
    pending 'does not allow to send requests via Name and Email' do
      click_link 'I don\'t have a SUNet ID'
      expect(page).not_to have_field('Name', type: 'text')
      expect(page).not_to have_field('Email', type: 'email')
    end
  end

  describe 'Mediated Pages' do
    describe 'for non-HOPKINS libraries' do
      # TODO: COVID-19
      pending 'allows users to submit without a SUNet ID' do
        visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')
        expect(page).to have_css('a', text: 'I don\'t have a SUNet ID')
      end
    end

    describe 'for HOPKINS' do
      it 'only allows to send request via WebAuth login' do
        visit new_page_path(item_id: '1234', origin: 'HOPKINS', origin_location: 'STACKS')
        expect(page).to have_css('button', text: /Send request.*login with SUNet ID/)
        expect(page).not_to have_css('a', text: 'I don\'t have a SUNet ID')
      end
    end
  end
end

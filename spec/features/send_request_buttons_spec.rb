# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Send Request Buttons' do
  let(:selected_items) do
    [
      double(:item, callnumber: 'ABC 123', checked_out?: false, processing?: false, missing?: false, hold?: false, on_order?: false,
                    pageable?: true, mediateable?: mediateable, hold_recallable?: false, barcode: '12345678', type: 'STKS',
                    effective_location: build(:location), permanent_location: build(:location), requestable?: true,
                    material_type: build(:book_material_type), loan_type: double(id: nil))
    ]
  end
  let(:mediateable) { false }

  let(:instance) do
    instance_double(Folio::Instance, title: 'Test title', request_holdings: selected_items, items: [])
  end

  before do
    allow(Settings.ils.bib_model.constantize).to receive(:fetch).and_return(instance)
  end

  describe 'as a Stanford user', :js do
    before { stub_current_user(create(:sso_user)) }

    it 'allows submit' do
      visit new_page_path(item_id: '1234', origin: 'SAL3', origin_location: 'SAL3-STACKS')

      click_on 'Send request'

      expect_to_be_on_success_page
    end
  end

  describe 'by anonymous user', :js do
    it 'is possible to toggle between login and name-email form' do
      visit new_page_path(item_id: '1234', origin: 'SAL3', origin_location: 'SAL3-STACKS')
      click_on 'I don\'t have a SUNet ID'

      expect(page).to have_field('Name', type: 'text')
      expect(page).to have_field('Email', type: 'email')
      expect(page).to have_css('a', text: '‹ Go back (show the login option)')

      click_on '‹ Go back (show the login option)'
      expect(page).to have_css('a', text: 'I don\'t have a SUNet ID')
    end

    it 'disables the submit button (and adds a tooltip) when additional user validation is needed' do
      visit new_page_path(item_id: '1234', origin: 'SAL3', origin_location: 'SAL3-STACKS')
      click_on 'I don\'t have a SUNet ID'

      expect(page).to have_field('University ID', type: 'text')
      expect(page).to have_field('Name', type: 'text')
      expect(page).to have_field('Email', type: 'email')

      expect(page).to have_css('input[value="Send request"][disabled].disabled')

      fill_in 'University ID', with: '12345678'
      expect(page).to have_css('input[value="Send request"].disabled')

      fill_in 'University ID', with: ''
      expect(page).to have_css('input[value="Send request"].disabled')

      fill_in 'Name', with: 'Jane Stanford'
      expect(page).to have_css('input[value="Send request"].disabled')
      fill_in 'Email', with: 'jstanford@stanford.edu'
      expect(page).to have_no_css('input[value="Send request"].disabled')
    end
  end

  describe 'for HOPKINS' do
    it 'allows to send request via SSO login or a SUNet ID' do
      visit new_page_path(item_id: '1234', origin: 'MARINE-BIO', origin_location: 'MAR-STACKS')
      expect(page).to have_css('button', text: /Send request.*login with SUNet ID/)
      expect(page).to have_css('a', text: 'I don\'t have a SUNet ID')
    end
  end

  describe 'Scans' do
    before do
      stub_bib_data_json(build(:scannable_holdings))
      visit new_scan_path(item_id: '12345', origin: 'SAL3', origin_location: 'SAL3-STACKS')
    end

    it 'only allows to send request via SSO login' do
      expect(page).to have_css('button', text: /Send request.*login with SUNet ID/)
      expect(page).to have_no_css('a', text: 'I don\'t have a SUNet ID')
    end

    it 'has a link to request the physical item' do
      expect(page).to have_css('a', text: 'Request the physical item')
    end
  end

  describe 'HoldRecall', :js do
    before do
      visit new_hold_recall_path(item_id: '1234', barcode: '3610512345', origin: 'GREEN', origin_location: 'GRE-STACKS')
    end

    it 'allows to send requests via SUNet ID' do
      expect(page).to have_css('button', text: /Send request.*login with SUNet ID/m)
    end

    it 'allows to send requests via University ID' do
      click_on 'I don\'t have a SUNet ID'
      expect(page).to have_field('University ID', type: 'text')
    end

    it 'does not allow to send requests via Name and Email' do
      click_on 'I don\'t have a SUNet ID'
      expect(page).to have_no_field('Name', type: 'text')
      expect(page).to have_no_field('Email', type: 'email')
    end
  end

  describe 'Mediated Pages' do
    let(:mediateable) { true }

    before do
      stub_bib_data_json(build(:single_mediated_holding))
    end

    it 'allows users to submit without a SUNet ID' do
      visit new_mediated_page_path(item_id: '1234', origin: 'ART', origin_location: 'ART-LOCKED-LARGE')
      expect(page).to have_css('a', text: 'I don\'t have a SUNet ID')
    end
  end
end

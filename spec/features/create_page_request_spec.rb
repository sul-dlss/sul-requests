# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a page request' do
  let(:user) { create(:sso_user) }

  let(:folio_holding_response) do
    { 'instanceId' => 'f1c52ab3-721e-5234-9a00-1023e034e2e8',
      'source' => 'MARC',
      'modeOfIssuance' => 'single unit',
      'natureOfContent' => [],
      'holdings' => [],
      'items' =>
       [{ 'id' => '584baef9-ea2f-5ff5-9947-bbc348aee4a4',
          'notes' => [],
          'status' => 'Available',
          'barcode' => '3610512345678',
          'location' =>
          { 'effectiveLocation' => { 'code' => 'GRE-STACKS' },
            'permanentLocation' => { 'code' => 'GRE-STACKS' },
            'temporaryLocation' => {} },
          'callNumber' =>
            { 'typeId' => '6caca63e-5651-4db6-9247-3205156e9699', 'typeName' => 'Other scheme', 'callNumber' => 'ABC 123' },
          'materialType' => 'periodical',
          'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
          'permanentLoanType' => 'Can circulate',
          'suppressFromDiscovery' => false },
        { 'id' => '99466f50-2b8c-51d4-8890-373190b8f6c4',
          'notes' => [],
          'status' => 'Available',
          'barcode' => '3610587654321',
          'location' =>
          { 'effectiveLocation' => { 'code' => 'GRE-STACKS' },
            'permanentLocation' => { 'code' => 'GRE-STACKS' },
            'temporaryLocation' => {} },
          'callNumber' =>
            { 'typeId' => '6caca63e-5651-4db6-9247-3205156e9699', 'typeName' => 'Other scheme', 'callNumber' => 'ABC 321' },
          'materialType' => 'periodical',
          'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
          'permanentLoanType' => 'Can circulate',
          'suppressFromDiscovery' => false }] }
  end

  before do
    allow(Request.ils_job_class).to receive(:perform_now)
    allow_any_instance_of(FolioClient).to receive(:find_instance).and_return({ indexTitle: 'Item Title' })
    allow_any_instance_of(FolioClient).to receive(:resolve_to_instance_id).and_return('f1c52ab3-721e-5234-9a00-1023e034e2e8')
    allow_any_instance_of(FolioClient).to receive(:items_and_holdings).and_return(folio_holding_response)
  end

  describe 'item information' do
    it 'displays the items title' do
      visit new_page_path(item_id: '2824966', origin: 'GREEN', origin_location: 'STACKS')
    end
  end

  context 'when initiated by an anonmyous user' do
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

    context 'when both library ID and email are provided by the user' do
      before do
        User.create!(library_id: '1011', email: 'tcramer1@stanford.edu')
      end

      it 'creates a new user', js: true do
        visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')
        click_link "I don't have a SUNet ID"

        fill_in 'Library ID', with: '123456'
        fill_in 'Name', with: 'Tim Cramer'
        fill_in 'Email', with: 'tcramer1@stanford.edu'

        click_button 'Send request'

        # Verify that the old record was not overwritten when the new request was created
        expect(User.where(email: 'tcramer1@stanford.edu').count).to eq 2
        expect_to_be_on_success_page
      end
    end
  end

  describe 'by a SSO user' do
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
        'We\'ll send you an email at some-sso-user@stanford.edu when processing is complete.'
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
end

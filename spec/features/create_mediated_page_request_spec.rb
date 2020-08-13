# frozen_string_literal: true

require 'rails_helper'

describe 'Creating a mediated page request' do
  let(:user) { create(:webauth_user) }

  before do
    allow_any_instance_of(PagingSchedule::Scheduler).to receive(:valid?).with(anything).and_return(true)
  end

  # TODO: COVID-19
  pending 'by an anonmyous user' do
    it 'is possible to toggle between login and name-email form', js: true do
      visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')

      click_remote_user_confirmation

      click_link "I don't have a SUNet ID"

      expect(page).to have_field('Library ID', type: 'text')
      expect(page).to have_field('Name', type: 'text')
      expect(page).to have_field('Email', type: 'email')
      expect(page).to have_css('a', text: '‹ Go back (show the login option)')
      expect(page).to have_css('input#request_user_attributes_library_id')
      expect(page.evaluate_script('document.activeElement.id')).to eq 'request_user_attributes_library_id'

      click_link '‹ Go back (show the login option)'
      expect(page).to have_css('a', text: "I don't have a SUNet ID")
    end

    it 'is possible if a name and email is filled out', js: true do
      visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')

      click_remote_user_confirmation

      fill_in_required_fields

      click_link "I don't have a SUNet ID"

      fill_in 'Name', with: 'Jane Stanford'
      fill_in 'Email', with: 'jstanford@stanford.edu'

      click_button 'Send request'
      expect_to_be_on_success_page
    end

    it 'is possible if a library id is filled out', js: true do
      visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')

      click_remote_user_confirmation

      fill_in_required_fields

      click_link "I don't have a SUNet ID"

      expect(page).to have_css('input#request_user_attributes_library_id')
      expect(page.evaluate_script('document.activeElement.id')).to eq 'request_user_attributes_library_id'

      fill_in 'Library ID', with: '123456'
      fill_in 'Name', with: 'Jane Stanford'
      fill_in 'Email', with: 'jstanford@stanford.edu'

      click_button 'Send request'

      expect(MediatedPage.last.user).to eq User.last
      expect(User.last.library_id).to eq '123456'
      expect_to_be_on_success_page
    end

    it 'does not have library ID/name/email fields if the request is from HOPKINS' do
      visit new_mediated_page_path(item_id: '1234', origin: 'HOPKINS', origin_location: 'STACKS')

      expect(page).not_to have_link('I don\'t have a SUNet ID')
      expect(page).not_to have_field('Library ID')
      expect(page).not_to have_field('Name')
      expect(page).not_to have_field('Email')
    end
  end

  describe 'by a webauth user' do
    before { stub_current_user(user) }

    it 'is possible without filling in any user information' do
      visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')

      fill_in_required_fields

      first(:button, 'Send request').click

      expect(current_url).to eq successful_mediated_page_url(MediatedPage.last)
      expect_to_be_on_success_page
    end
  end

  describe 'comments' do
    before { stub_current_user(user) }

    it 'has a comments field for commentable libraries' do
      visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')

      fill_in_required_fields

      comment = '1989, Mar: Le Monde'
      fill_in 'Comment', with: comment

      first(:button, 'Send request').click

      expect_to_be_on_success_page

      expect(MediatedPage.last.request_comment).to eq comment
    end

    it 'does not include a comments for requests that do not get them' do
      visit new_mediated_page_path(item_id: '1234', origin: 'HV-ARCHIVE', origin_location: 'STACKS-30')

      expect(page).not_to have_field('Comments')
    end
  end

  # TODO: COVID-19 We are not collecting needed_date currently
  pending 'needed on' do
    before { stub_current_user(user) }

    it 'has a field for the planned date of visit' do
      visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')
      date = (Time.zone.now + 1.day).to_date

      fill_in 'I plan to visit on', with: date

      first(:button, 'Send request').click

      expect_to_be_on_success_page

      expect(MediatedPage.last.needed_date).to eq date
    end
  end

  describe 'selecting barcodes' do
    before do
      stub_current_user(user)
      stub_searchworks_api_json(build(:special_collections_holdings))
    end

    it 'persists to the database' do
      visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')

      fill_in_required_fields

      within('#item-selector') do
        check('ABC 123')
      end

      first(:button, 'Send request').click

      expect_to_be_on_success_page

      expect(MediatedPage.last.barcodes).to eq(%w(12345678))
    end
  end

  describe 'special note for SPEC items about reading room access' do
    before { stub_current_user(user) }

    it 'is present' do
      visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')

      expect(page).to have_css('.col-form-label', text: 'Reading Room access')
      expect(page).to have_css('.input-like-text', text: /^When the items have been approved and are ready for use/)
    end
  end

  def fill_in_required_fields
    # TODO: COVID-19 We are not collecting needed_date currently
    # if Capybara.current_driver == :rack_test
    #   date_input = find('#request_needed_date', visible: :hidden)
    #   min_date = date_input['min']
    #   date_input.set(min_date)
    # else
    #   wait_for_ajax
    #   min_date = find('#request_needed_date', visible: :hidden)['min']
    #   page.execute_script("$('#request_needed_date').prop('value', '#{min_date}')")
    # end
  end

  def click_remote_user_confirmation
    within('.non-stanford-user-overlay') do
      click_button
    end
  end
end

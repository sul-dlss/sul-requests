# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Edit Aeon request', :js do
  use_stub_aeon_client

  let(:user) { create(:sso_user) }
  let(:current_user) { CurrentUser.new(username: user.sunetid, shibboleth: true) }
  let(:aeon_user) { StubAeonClient::User.create(username: user.email_address, authType: 'Default') }

  let(:appointment) do
    create(:remote_aeon_appointment, username: aeon_user.username, reading_room:, startTime: 1.week.from_now,
                                     stopTime: 1.week.from_now + 1.hour)
  end
  let(:reading_room) { StubAeonClient::ReadingRoom.find_by(name: 'Field Reading Room') }

  let(:first_request) do
    StubAeonClient::Request.create(
      id: 100,
      callNumber: 'PR9195.1 .S56 NO.1',
      itemAuthor: 'Percy Poet',
      itemInfo1: 'https://searchworks.stanford.edu/view/12345678',
      itemTitle: 'Slow poetry in America : a poetry quarterly',
      username: aeon_user.username,
      webRequestForm: 'single',
      site: 'SPECUA'
    )
  end

  before do
    first_request
    login_as(current_user)
    visit aeon_requests_path(kind: 'saved_for_later')
  end

  describe 'Saved for later page' do
    it 'displays the page header' do
      expect(page).to have_css('h1', text: 'Saved for later')
    end

    it 'displays the request with proper record header' do
      expect(page).to have_css('h2', text: 'Slow poetry in America : a poetry quarterly')
      expect(page).to have_text('Call number: PR9195.1')
      expect(page).to have_link('View in SearchWorks', href: first_request.itemInfo1)
    end
  end

  describe 'editing a request' do
    before do
      click_link('Add appointment')
    end

    it 'Opens the edit modal' do
      expect(page).to have_current_path(aeon_requests_path(kind: 'saved_for_later'))
      expect(page).to have_css('.modal-header h1', text: 'Edit request')
      expect(page).to have_css('.selected-item-title', text: 'PR9195.1 .S56 NO.1')
    end

    # This serves to test RecordHeaderCardComponent
    it 'Displays the long form of the record header in the edit modal' do
      expect(page).to have_css('.card .card-body h2', text: 'Slow poetry in America : a poetry quarterly')
      within('.modal-dialog .card .card-body') do
        expect(page).to have_css('.mt-2', text: 'Percy Poet')
      end
    end

    it 'Displays the reading room' do
      expect(page).to have_css('.modal-body', text: 'Field Reading Room')
    end

    it 'Navigates between the create appointment modal and edit modal' do
      expect(page).to have_css('.modal-header h1', text: 'Edit request')
      click_link('Create new appointment')
      # The appointment creation functionality is tested elsewhere but this shows that the modal opens and closes
      expect(page).to have_css('.modal-header h1', text: 'Create new appointment')
      click_link('Cancel')
      expect(page).to have_css('.modal-header h1', text: 'Edit request')
    end
  end
end

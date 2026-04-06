# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Edit Aeon request', :js do
  let(:user) { create(:sso_user) }
  let(:current_user) { CurrentUser.new(username: user.sunetid, shibboleth: true, patron_key: user.patron_key, ldap_attributes: {}) }
  let(:aeon_user) { Aeon::User.new(username: user.email_address, auth_type: 'Default') }
  let(:reading_room) { build(:aeon_reading_room) }
  let(:appointment) { build(:aeon_appointment, reading_room: reading_room, start_time: 1.week.from_now) }
  let(:first_request) do
    build(:aeon_request, call_number: 'PR9195.1 .S56 NO.1', title: 'Slow poetry in America : a poetry quarterly', item_author: 'Percy Poet',
                         transaction_number: 100, username: aeon_user.username)
  end
  let(:draft_queue) do
    Aeon::Queue.new(id: 5, queue_name: 'Awaiting User Review', queue_type: 'Transaction')
  end
  let(:stub_aeon_client) do
    instance_double(AeonClient,
                    find_user: aeon_user,
                    find_queue: draft_queue,
                    appointments_for: [appointment],
                    requests_for: [first_request],
                    reading_rooms: [reading_room],
                    available_appointments: [])
  end

  before do
    allow(AeonClient).to receive(:new).and_return(stub_aeon_client)
    allow(aeon_user).to receive_messages(requests: [first_request])
    allow(Aeon::ReadingRoom).to receive(:find_by).and_return(reading_room)
    login_as(current_user)
    visit draft_aeon_requests_path
  end

  describe 'drafts page' do
    it 'displays the page header' do
      expect(page).to have_css('h1', text: 'Draft requests')
    end

    it 'displays the request with proper record header' do
      expect(page).to have_css('h2', text: 'Slow poetry in America : a poetry quarterly')
      expect(page).to have_content('Call number: PR9195.1')
      expect(page).to have_link('View in SearchWorks', href: first_request.item_info1)
    end
  end

  describe 'editing a request' do
    before do
      click_link('Edit request')
    end

    it 'Opens the edit modal' do
      expect(page).to have_current_path(draft_aeon_requests_path)
      expect(page).to have_css('.modal-header h1', text: 'Edit request')
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
      click_button('Cancel')
      expect(page).to have_css('.modal-header h1', text: 'Edit request')
    end
  end
end

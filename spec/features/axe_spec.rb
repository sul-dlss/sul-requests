# frozen_string_literal: true

require 'rails_helper'
require 'axe-rspec'

RSpec.describe 'Accessibility testing', :js do
  let(:user_object) { build(:sso_user) }
  let(:folio_instance) { build(:sal3_holding) }

  before do
    stub_folio_instance_json(folio_instance)
  end

  # TODO: once user login is available add user mocks
  # TODO: add patron_request_path after built out more
  describe 'without user login' do
    it 'validates the home page' do
      visit new_patron_request_path(instance_hrid: 'a12345', origin_location_code: 'SAL3-STACKS')
      expect(page).to be_accessible
    end

    it 'validates the feedback form page' do
      visit feedback_form_path
      expect(page).to be_accessible
    end
  end

  context 'with a user' do
    let(:user) { instance_double(CurrentUser, user_object:, shibboleth?: true, name_email_user?: false) }
    let(:patron) { build(:patron) }

    before do
      login_as(user)
      allow(Folio::Patron).to receive(:find_by).with(patron_key: user_object.patron_key).and_return(patron)
    end

    it 'validates the request page' do
      visit new_patron_request_path(instance_hrid: 'a12345', origin_location_code: 'SAL3-STACKS', step: 'select')
      expect(page).to be_accessible
    end

    context 'when the user is blocked' do
      let(:patron) { build(:blocked_patron) }

      it 'validates the request page' do
        visit new_patron_request_path(instance_hrid: 'a12345', origin_location_code: 'SAL3-STACKS', step: 'select')
        expect(page).to be_accessible
      end
    end
  end

  context 'with multiple items to pick from' do
    let(:folio_instance) { build(:checkedout_holdings) }

    let(:user) { create(:sso_user) }
    let(:patron) { build(:patron) }
    let(:current_user) { CurrentUser.new(username: user.sunetid, patron_key: user.patron_key, shibboleth: true, ldap_attributes:) }
    let(:ldap_attributes) { {} }

    before do
      allow(Folio::Patron).to receive(:find_by).with(patron_key: user.patron_key).and_return(patron)
      login_as(current_user)
    end

    it 'validates the multi-item selector steps' do
      visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')

      expect(page).to be_accessible

      check 'ABC 123'
      click_on 'Continue'
      expect(page).to be_accessible

      click_on 'Submit request'
      expect(page).to be_accessible
    end
  end

  context 'for a scan' do
    let(:folio_instance) { build(:scannable_holdings) }
    let(:user) { create(:scan_eligible_user) }
    let(:patron) { build(:patron) }
    let(:current_user) { CurrentUser.new(username: user.sunetid, patron_key: user.patron_key, shibboleth: true, ldap_attributes:) }
    let(:ldap_attributes) { {} }

    before do
      allow(Folio::Patron).to receive(:find_by).with(patron_key: user.patron_key).and_return(patron)
      login_as(current_user)
      allow(current_user).to receive(:user_object).and_return(user)
    end

    it 'validates the scan form' do
      visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')

      expect(page).to be_accessible
      choose 'Email digital scan'
      click_on 'Continue'
      expect(page).to be_accessible
      choose 'ABC 123'
      click_on 'Continue'
      expect(page).to be_accessible
    end
  end

  context 'for saved for later and submitted (grouped) requests pages' do
    let(:user) { create(:sso_user) }
    let(:current_user) { CurrentUser.new(username: user.sunetid, shibboleth: true) }
    let(:aeon_user) { Aeon::User.new(username: user.email_address, auth_type: 'Default') }
    let(:reading_room) { build(:aeon_reading_room) }
    let(:appointment) { build(:aeon_appointment, reading_room: reading_room, start_time: 1.week.from_now) }
    let(:physical_request) { build(:aeon_request, username: aeon_user.username, transaction_number: 100) }
    let(:digital_request) do
      build(:aeon_request, :digitized, username: aeon_user.username, transaction_number: 101,
                                       item_info5: 'Pages 1-10')
    end
    let(:multi_item_requests) do
      [
        build(:aeon_request, username: aeon_user.username, transaction_number: 102,
                             web_request_form: 'multiple', item_title: 'Grouped title'),
        build(:aeon_request, username: aeon_user.username, transaction_number: 103,
                             web_request_form: 'multiple', item_title: 'Grouped title')
      ]
    end
    let(:all_requests) { [physical_request, digital_request] + multi_item_requests }
    let(:queue) { Aeon::Queue.new(id: 5, queue_name: queue_name, queue_type: 'Transaction') }
    let(:stub_aeon_client) do
      instance_double(AeonClient,
                      find_user: aeon_user,
                      find_queue: queue,
                      requests_for: all_requests,
                      activities: [],
                      appointments_for: [appointment])
    end

    before do
      allow(AeonClient).to receive(:new).and_return(stub_aeon_client)
      login_as(current_user)
    end

    context 'with saved for later requests' do
      let(:queue_name) { 'Awaiting User Review' }

      it 'validates the saved for later page' do
        visit aeon_requests_path(kind: 'saved_for_later')
        expect(page).to be_accessible
      end
    end

    context 'with submitted requests' do
      let(:queue_name) { 'In Processing' }

      it 'validates the submitted page' do
        visit aeon_requests_path(kind: 'submitted')
        expect(page).to be_accessible
      end
    end
  end

  it 'validates the feedback form page' do
    visit feedback_form_path
    expect(page).to be_accessible
  end

  context 'for the folio checkouts page' do
    let(:mock_client) { instance_double(FolioClient, ping: true, find_effective_loan_policy: {}, find_overdue_fines_policy: {}) }
    let(:loan_policy) { build(:grad_mono_loans) }
    let(:patron) { build(:sponsor_patron) }
    let(:current_user) { CurrentUser.new(username: 'stub_user', patron_key: '513a9054-5897-11ee-8c99-0242ac120002', shibboleth: true) }

    before do
      allow(FolioClient).to receive(:new).and_return(mock_client)
      allow(Folio::LoanPolicy).to receive(:new).and_return(loan_policy)
      allow(Folio::Patron).to receive(:find_by).with(patron_key: '513a9054-5897-11ee-8c99-0242ac120002').and_return(patron)
      login_as(current_user)
    end

    it 'validates the checkouts page with items' do
      visit checkouts_path
      expect(page).to be_accessible
    end

    context 'when a patron has overdue items' do
      let(:patron) { build(:patron_with_overdue_items) }

      it 'validates the checkouts page with overdue messaging' do
        visit checkouts_path
        expect(page).to be_accessible
      end
    end

    context 'with no checkouts' do
      let(:patron_info) do
        {
          'user' => { 'active' => true, 'manualBlocks' => [], 'blocks' => [], 'id' => 'userid' },
          'loans' => [],
          'holds' => [],
          'accounts' => []
        }
      end
      let(:patron) { Folio::Patron.new(patron_graphql_response: patron_info) }

      it 'validates the empty checkouts page' do
        visit checkouts_path
        expect(page).to be_accessible
      end
    end
  end

  context 'for the folio fines page' do
    let(:mock_client) { instance_double(FolioClient, ping: true) }
    let(:patron) { build(:patron_with_fines) }
    let(:current_user) { CurrentUser.new(username: 'stub_user', patron_key: '513a9054-5897-11ee-8c99-0242ac120002', shibboleth: true) }

    before do
      allow(FolioClient).to receive(:new).and_return(mock_client)
      allow(patron).to receive(:checkouts).and_return([])
      allow(Folio::Patron).to receive(:find_by).with(patron_key: '513a9054-5897-11ee-8c99-0242ac120002').and_return(patron)
      login_as(current_user)
    end

    it 'validates the fines page with outstanding fines' do
      visit fines_path
      expect(page).to be_accessible
    end

    context 'with proxy-borrower fines' do
      let(:patron) { build(:sponsor_patron) }

      it 'validates the fines page with proxy badges' do
        visit fines_path
        expect(page).to be_accessible
      end
    end

    context 'with no fines' do
      let(:patron_info) do
        {
          'user' => { 'active' => true, 'manualBlocks' => [], 'blocks' => [], 'id' => 'userid' },
          'loans' => [],
          'holds' => [],
          'accounts' => []
        }
      end
      let(:patron) { Folio::Patron.new(patron_graphql_response: patron_info) }

      it 'validates the empty fines page' do
        visit fines_path
        expect(page).to be_accessible
      end
    end
  end

  context 'for the appointment date picker component' do
    let(:user) { create(:sso_user) }
    let(:current_user) { CurrentUser.new(username: user.sunetid, shibboleth: true) }
    let(:aeon_user) { Aeon::User.new(username: user.email_address, auth_type: 'Default') }
    let(:reading_room) { build(:aeon_reading_room) }
    let(:stub_aeon_client) do
      instance_double(AeonClient,
                      find_user: aeon_user,
                      activities: [],
                      closures: [],
                      appointments_for: [],
                      available_appointments: [],
                      reading_rooms: [reading_room])
    end

    before do
      allow(AeonClient).to receive(:new).and_return(stub_aeon_client)
      login_as(current_user)
    end

    it 'validates the custom stimulus datepicker' do
      visit new_aeon_appointment_path(aeon_appointment: { reading_room_id: reading_room.id })
      expect(page).to be_accessible

      find('[data-date-picker-target="button"]').click
      expect(page).to have_css('[data-date-picker-target="calendar"]:not([hidden])') # picker is open
      expect(page).to be_accessible
    end
  end

  def be_accessible
    be_axe_clean.with_options({ preload: false })
  end
end

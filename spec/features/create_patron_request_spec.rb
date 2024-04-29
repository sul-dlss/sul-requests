# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a request' do
  include ActiveJob::TestHelper

  let(:user) { create(:sso_user) }
  let(:bib_data) { build(:single_holding) }
  let(:patron) do
    instance_double(Folio::Patron, id: user.patron_key, username: 'auser', display_name: 'A User', exists?: true, email: nil,
                                   patron_description: 'faculty',
                                   patron_group_id: '503a81cd-6c26-400f-b620-14c08943697c',
                                   allowed_request_types: ['Hold', 'Recall', 'Page'],
                                   blocked?: true, fix_block_message: ['how to fix block'],
                                   ilb_eligible?: true, block_reasons: ['there is a block'],
                                   all_proxy_group_info: [])
  end

  before do
    stub_bib_data_json(bib_data)
    # this line prevents ArgumentError: SMTP To address may not be blank
    ActionMailer::Base.perform_deliveries = false
  end

  context 'with an SSO user' do
    let(:current_user) { CurrentUser.new(username: user.sunetid, patron_key: user.patron_key, shibboleth: true) }

    before do
      allow(Settings.ils.patron_model.constantize).to receive(:find_by).with(patron_key: user.patron_key).and_return(patron)
      login_as(current_user)
    end

    it 'submits the request for pick-up at Green' do
      visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')

      expect { click_on 'Submit' }.to change(PatronRequest, :count).by(1)

      expect(PatronRequest.last).to have_attributes(
        patron_id: user.patron_key,
        instance_hrid: 'a1234',
        origin_location_code: 'SAL3-STACKS',
        service_point_code: 'GREEN-LOAN'
      )
    end

    it 'allows the patron to choose a pickup location' do
      visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')

      select 'Marine Biology Library', from: 'Preferred pickup location'

      expect { click_on 'Submit' }.to change(PatronRequest, :count).by(1)

      expect(PatronRequest.last).to have_attributes(
        patron_id: user.patron_key,
        instance_hrid: 'a1234',
        origin_location_code: 'SAL3-STACKS',
        service_point_code: 'MARINE-BIO'
      )
    end

    it 'enqueues a job to submit the request to FOLIO' do
      folio_client = FolioClient.new
      allow(folio_client).to receive(:create_circulation_request)
      allow(FolioClient).to receive(:new).and_return(folio_client)
      allow(patron).to receive(:allowed_request_types).and_return(%w[Hold Page Recall])

      visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')

      perform_enqueued_jobs do
        click_on 'Submit'
      end

      expect(folio_client).to have_received(:create_circulation_request).with(have_attributes(requester_id: patron.id,
                                                                                              instance_id: bib_data.id))
    end

    context 'for a scan' do
      let(:bib_data) { build(:scannable_holdings) }
      let(:user) { create(:scan_eligible_user) }

      before do
        allow(current_user).to receive(:user_object).and_return(user)
      end

      it 'submits the scan request', :js do
        visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')

        choose 'Email digital scan'
        click_on 'Continue'
        choose 'ABC 123'
        click_on 'Continue'
        expect(page).to have_content 'Copyright notice'
        fill_in 'Page range', with: '1-15'
        fill_in 'Title of article or chapter', with: 'Some title'

        expect do
          click_on 'Submit'
          expect(page).to have_content 'We received your scan request'
        end.to change(PatronRequest, :count).by(1)
      end
    end

    context 'for a mediated page' do
      let(:bib_data) { build(:single_mediated_holding) }

      before do
        allow(patron).to receive(:user).and_return(user)
        allow_any_instance_of(PagingSchedule::Scheduler).to receive(:valid?).with(anything).and_return(true)
      end

      it 'creates a mediated page request', :js do
        visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'ART-LOCKED-LARGE')

        expect do
          perform_enqueued_jobs do
            click_on 'Submit'
            expect(page).to have_content 'We received your request'
          end
        end.to change(MediatedPage, :count).by(1)

        expect(MediatedPage.last).to have_attributes(
          origin: 'ART',
          origin_location: 'ART-LOCKED-LARGE',
          item_id: 'a1234',
          user:,
          barcodes: ['12345678'],
          item_title: 'Item Title'
        )
      end
    end

    context 'for an item that can be paged or scanned', :js do
      let(:bib_data) { build(:scannable_holdings) }
      let(:user) { create(:scan_eligible_user) }

      before do
        allow(current_user).to receive(:user_object).and_return(user)
      end

      it 'allows paging' do
        # FIXME
        skip('flappy') if ENV['CI']

        visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')

        choose 'Pickup physical item'
        click_on 'Continue'
        check 'ABC 123'
        click_on 'Continue'
        expect(page).to have_content 'Pickup request'
        click_on 'Submit'
        expect(page).to have_content 'We received your pickup request'
      end

      it 'allows scanning' do
        visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')

        choose 'Email digital scan'
        click_on 'Continue'
        choose 'ABC 123'
        click_on 'Continue'
        expect(page).to have_content 'Copyright notice'
        fill_in 'Page range', with: '1-15'
        fill_in 'Title of article or chapter', with: 'Some title'
        click_on 'Submit'
        expect(page).to have_content 'We received your scan request'
      end
    end

    context 'with stubbed paging schedule' do
      before do
        travel_to Time.zone.local(2024, 4, 2, 12, 0, 0)

        allow_any_instance_of(LibraryHours).to receive(:open?).and_return(true)

        allow(PagingSchedule).to receive(:schedule).and_return(
          [
            PagingSchedule::Scheduler.new(from: 'SAL3', to: 'GREEN', before: '11:59pm', business_days_later: 1, will_arrive_after: '10am'),
            PagingSchedule::Scheduler.new(from: 'SAL3', to: 'MARINE-BIO', before: '11:59pm', business_days_later: 3,
                                          will_arrive_after: '4pm')
          ]
        )
      end

      it 'shows the estimated deliver dates', :js do
        # FIXME
        skip('flappy') if ENV['CI']

        visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')

        within '#earliestAvailableContainer' do
          expect(page).to have_content('Wednesday, Apr 3, 2024 after 10am')
        end

        select 'Marine Biology Library', from: 'Preferred pickup location'
        within '#earliestAvailableContainer' do
          expect(page).to have_content('Friday, Apr 5, 2024 after 4pm')
        end
      end
    end

    context 'when the user does not have an account in FOLIO' do
      let(:current_user) { CurrentUser.new(username: user.sunetid, shibboleth: true) }
      let(:patron) { Folio::NullPatron.new(user) }

      before do
        allow(Settings.ils.patron_model.constantize).to receive(:find_by).with(sunetid: user.sunetid).and_return(patron)
        login_as(current_user)
      end

      it 'redirects to the login page' do
        visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')
        expect(page).to have_text 'Login with Library ID/PIN'
      end

      it 'shows an error message' do
        visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')
        expect(page).to have_content('Your SUNet ID is not linked to a library account')
      end
    end
  end

  context 'with a library ID user' do
    let(:stub_client) { FolioClient.new }
    let(:patron) do
      instance_double(Folio::Patron, id: 'some-lib-id-uuid', display_name: 'A User', exists?: true, email: nil,
                                     allowed_request_types: ['Hold', 'Page'],
                                     patron_group_id: '985acbb9-f7a7-4f44-9b34-458c02a78fbc',
                                     blocked?: false, fix_block_message: [],
                                     patron_description: 'courtesy', ilb_eligible?: true, block_reasons: [], all_proxy_group_info: [])
    end

    before do
      allow(FolioClient).to receive(:new).and_return(stub_client)

      allow(stub_client).to receive(:login_by_barcode).with('12345', '54321').and_return({ 'patronKey' => 'some-lib-id-uuid' })
      allow(Settings.ils.patron_model.constantize).to receive(:find_by).with(patron_key: 'some-lib-id-uuid').and_return(patron)
    end

    it 'submits the request for pickup at Green' do
      visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')
      first('summary').click

      fill_in 'Library ID', with: '12345'
      fill_in 'PIN', with: '54321'

      click_on 'Login'

      expect { click_on 'Submit' }.to change(PatronRequest, :count).by(1)

      expect(PatronRequest.last).to have_attributes(
        patron_id: 'some-lib-id-uuid',
        instance_hrid: 'a1234',
        origin_location_code: 'SAL3-STACKS',
        service_point_code: 'GREEN-LOAN'
      )
    end

    context 'when circ rules prevent any request on the item for the patron' do
      let(:patron) do
        instance_double(Folio::Patron, id: 'some-lib-id-uuid', display_name: 'A User', exists?: true, email: nil,
                                       allowed_request_types: [], blocked?: false,
                                       patron_group_id: '985acbb9-f7a7-4f44-9b34-458c02a78fbc',
                                       fix_block_message: [],
                                       patron_description: 'courtesy', ilb_eligible?: true, block_reasons: [], all_proxy_group_info: [])
      end

      let(:bib_data) { build(:single_holding, items: [build(:item, effective_location: build(:law_location))]) }

      it 'goes to a dead-end page', :js do
        visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'LAW-STACKS1')
        first('summary').click

        fill_in 'Library ID', with: '12345'
        fill_in 'PIN', with: '54321'

        click_on 'Login'
        expect(page).to have_content('This item is not requestable at this time')
      end
    end

    context 'when logged in' do
      let(:current_user) { CurrentUser.new(patron_key: patron.id) }

      before do
        login_as(current_user)
      end

      it 'goes directly to the request form' do
        visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')
        expect(page).to have_button 'Submit'
      end
    end
  end

  context 'with a library name+email user' do
    context 'for an item that a purchased account cannot page' do
      let(:bib_data) { build(:single_holding, items: [build(:item, effective_location: build(:law_location))]) }

      it 'shows the user a warning message' do
        visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'LAW-STACKS1')
        expect(page).to have_content('This item is not available to request for visitors')
      end
    end

    it 'logs the user out before creating a request', :js do
      visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')
      find('summary', text: 'Proceed as visitor').click
      fill_in 'Name', with: 'My Name'
      fill_in 'Email', with: 'me@example.com'
      click_on 'Continue'
      click_on 'Submit'
      visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')
      expect(page).to have_text 'Login with Library ID/PIN'
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a request', :js do
  let(:user) { create(:sso_user) }
  let(:bib_data) { build(:single_holding) }
  let(:patron) { build(:patron) }

  before do
    stub_bib_data_json(bib_data)
    # this line prevents ArgumentError: SMTP To address may not be blank
    ActionMailer::Base.perform_deliveries = false

    allow(Settings.ils.patron_model.constantize).to receive(:find_by).with(patron_key: 'generic').and_return(build(:patron))
  end

  after do
    logout
  end

  context 'with an SSO user' do
    let(:current_user) { CurrentUser.new(username: user.sunetid, patron_key: user.patron_key, shibboleth: true, ldap_attributes:) }
    let(:ldap_attributes) { {} }

    before do
      allow(Settings.ils.patron_model.constantize).to receive(:find_by).with(patron_key: user.patron_key).and_return(patron)
      login_as(current_user)
    end

    it 'submits the request for pick-up at Green' do
      visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')

      expect do
        perform_enqueued_jobs do
          click_on 'Submit request'
        end
        expect(page).to have_content 'We received your pickup request'
      end.to change(PatronRequest, :count).by(1)

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

      expect do
        perform_enqueued_jobs do
          click_on 'Submit request'
        end
        expect(page).to have_content 'We received your pickup request'
      end.to change(PatronRequest, :count).by(1)

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
        click_on 'Submit request'
        expect(page).to have_content 'We received your pickup request'
      end
      expect(folio_client).to have_received(:create_circulation_request).with(have_attributes(requester_id: patron.id,
                                                                                              instance_id: bib_data.id))
    end

    context 'for a bound-with item' do
      let(:bib_data) { build(:bound_with_child_holding) }

      it 'submits the request for the bound-with parent instance' do
        folio_client = FolioClient.new
        allow(folio_client).to receive(:create_circulation_request)
        allow(FolioClient).to receive(:new).and_return(folio_client)
        allow(patron).to receive(:allowed_request_types).and_return(%w[Hold Page Recall])

        visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')

        perform_enqueued_jobs do
          click_on 'Submit request'
          expect(page).to have_content 'We received your pickup request'
          expect(page).to have_content 'This item is bound with other items and is shelved under the title Bound with parent (ABC 123)'
        end
        expect(folio_client).to have_received(:create_circulation_request).with(have_attributes(requester_id: patron.id,
                                                                                                instance_id: '9876'))
      end
    end

    context 'for a scan' do
      let(:bib_data) { build(:scannable_holdings) }
      let(:user) { create(:scan_eligible_user) }

      before do
        allow(current_user).to receive(:user_object).and_return(user)
      end

      it 'submits the scan request' do
        visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')

        choose 'Email digital scan'
        click_on 'Continue'
        choose 'ABC 123'
        click_on 'Continue'
        expect(page).to have_content 'Copyright notice'
        fill_in 'Page range', with: '1-15'
        fill_in 'Title of article or chapter', with: 'Some title'
        fill_in 'Author(s)', with: 'Some author'

        expect do
          perform_enqueued_jobs do
            click_on 'Submit request'
          end
          expect(page).to have_content 'We received your scan request'
        end.to change(PatronRequest, :count).by(1)

        expect(PatronRequest.last).to have_attributes(
          scan_title: 'Some title',
          scan_authors: 'Some author'
        )
      end
    end

    context 'for a mediated page' do
      let(:bib_data) { build(:single_mediated_holding) }

      before do
        allow_any_instance_of(PagingSchedule).to receive(:valid?).with(anything).and_return(true)
      end

      it 'creates a mediated page request' do
        visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'ART-LOCKED-LARGE')

        expect do
          perform_enqueued_jobs do
            click_on 'Submit request'
            expect(page).to have_content 'We received your request'
          end
        end.to change(PatronRequest, :count).by(1)

        expect(PatronRequest.last).to have_attributes(request_type: 'mediated')
      end
    end

    context 'for a mediated page with an item selector' do
      let(:bib_data) { build(:searchable_holdings) }
      let(:today) { Time.zone.today }

      before do
        allow_any_instance_of(PagingSchedule).to receive(:valid?).with(anything).and_return(true)
        allow_any_instance_of(PagingSchedule).to receive(:earliest_delivery_estimate).and_return({ date: today.to_date })
      end

      it 'creates a mediated page request', :js do
        visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'ART-LOCKED-LARGE')

        expect(page).to have_css 'h2', text: 'Select item(s)'
        check 'ABC 123'
        check 'ABC 456'
        click_on 'Continue'

        fill_in 'I plan to visit on:', with: today.next_week(:monday)

        expect do
          perform_enqueued_jobs do
            click_on 'Submit request'
            expect(page).to have_content 'We received your request'
          end
        end.to change(PatronRequest, :count).by(1)

        expect(PatronRequest.last).to have_attributes(request_type: 'mediated')
      end
    end

    context 'for an item that can be paged or scanned' do
      let(:bib_data) { build(:scannable_holdings) }
      let(:user) { create(:scan_eligible_user) }

      before do
        allow(current_user).to receive(:user_object).and_return(user)
      end

      it 'allows paging' do
        visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')

        choose 'Pickup physical item'
        click_on 'Continue'
        check 'ABC 123'
        click_on 'Continue'
        expect(page).to have_content 'Pickup request'
        perform_enqueued_jobs do
          click_on 'Submit request'
        end
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
        perform_enqueued_jobs do
          click_on 'Submit request'
        end
        expect(page).to have_content 'We received your scan request'
      end
    end

    context 'with stubbed paging schedule' do
      before do
        allow(PagingSchedule).to receive(:new).with(
          from: have_attributes(code: 'SAL3-STACKS'),
          library_code: 'SAL3',
          to: 'GREEN-LOAN',
          time: nil
        ).and_return(
          instance_double(
            PagingSchedule, earliest_delivery_estimate: 'Wednesday, Apr 3, 2024, 10am'
          )
        )

        allow(PagingSchedule).to receive(:new).with(
          from: have_attributes(code: 'SAL3-STACKS'),
          library_code: 'SAL3',
          to: 'MARINE-BIO',
          time: nil
        ).and_return(
          instance_double(
            PagingSchedule, earliest_delivery_estimate: 'Wednesday, Apr 3, 2024, 4pm'
          )
        )
      end

      it 'shows the estimated deliver dates' do
        visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')

        within '#earliestAvailableContainer' do
          expect(page).to have_content('Wednesday, Apr 3, 2024, 10am')
        end

        select 'Marine Biology Library', from: 'Preferred pickup location'
        within '#earliestAvailableContainer' do
          expect(page).to have_content('Wednesday, Apr 3, 2024, 4pm')
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

    context 'for an item with temporary location' do
      let(:bib_data) { build(:temporary_location_holdings) }

      it 'allows user to request an item with needed by date' do
        visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')

        choose 'Pickup physical item'
        click_on 'Continue'
        expect(page).to have_text('Not needed after')
        needed_date = Date.parse(page.find_by_id('patron_request_needed_date').value)

        expect do
          perform_enqueued_jobs do
            click_on 'Submit request'
          end
          expect(page).to have_content 'We received your pickup request'
          expect(page).to have_text "Not needed after: #{needed_date.strftime('%b %-d, %Y')}"
        end.to change(PatronRequest, :count).by(1)

        expect(PatronRequest.last).to have_attributes(
          patron_id: user.patron_key,
          instance_hrid: 'a1234',
          origin_location_code: 'SAL3-STACKS',
          needed_date: needed_date
        )
      end
    end
  end

  context 'with a library ID user' do
    let(:stub_client) { FolioClient.new }
    let(:patron) do
      build(:library_id_patron)
    end

    before do
      allow(FolioClient).to receive(:new).and_return(stub_client)

      allow(stub_client).to receive(:login_by_barcode).with('12345', '54321').and_return({ 'patronKey' => 'some-lib-id-uuid' })
      allow(Settings.ils.patron_model.constantize).to receive(:find_by).with(patron_key: 'some-lib-id-uuid').and_return(patron)
    end

    it 'submits the request for pickup at Green' do
      logout
      visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')
      expect(page).to have_css 'summary', text: 'Login with Library ID/PIN'
      first('summary').click

      fill_in 'Library ID', with: '12345'
      fill_in 'PIN', with: '54321'

      click_on 'Login'

      expect do
        perform_enqueued_jobs do
          click_on 'Submit request'
        end
        expect(page).to have_content 'We received your pickup request'
      end.to change(PatronRequest, :count).by(1)

      expect(PatronRequest.last).to have_attributes(
        patron_id: 'some-lib-id-uuid',
        instance_hrid: 'a1234',
        origin_location_code: 'SAL3-STACKS',
        service_point_code: 'GREEN-LOAN'
      )
    end

    context 'when circ rules prevent any request on the item for the patron' do
      let(:bib_data) { build(:single_holding, items: [build(:item, effective_location: build(:law_location))]) }

      it 'goes to a dead-end page' do
        logout
        visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'LAW-STACKS1')
        expect(page).to have_css 'summary', text: 'Login with Library ID/PIN'
        first('summary').click

        fill_in 'Library ID', with: '12345'
        fill_in 'PIN', with: '54321'

        click_on 'Login'
        expect(page).to have_content('This item is not available to request for Stanford Libraries cardholders.')
      end
    end

    context 'when logged in' do
      let(:current_user) { CurrentUser.new(patron_key: patron.id) }

      before do
        login_as(current_user)
      end

      it 'goes directly to the request form' do
        visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')
        expect(page).to have_button 'Submit request'
      end
    end
  end

  context 'with a name+email user' do
    context 'for an item that a purchased account cannot page' do
      let(:bib_data) { build(:single_holding, items: [build(:item, effective_location: build(:law_location))]) }

      it 'shows the user a warning message' do
        visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'LAW-STACKS1')
        expect(page).to have_content('This item is not available to request for visitors')
      end
    end

    it 'logs the user out before creating a request' do
      visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')
      expect(page).to have_css 'summary', text: 'Proceed as visitor'
      find('summary', text: 'Proceed as visitor').click
      fill_in 'Name', with: 'My Name'
      fill_in 'Email', with: 'me@example.com'
      click_on 'Continue'

      expect(page).to have_button 'Submit request'

      perform_enqueued_jobs do
        click_on 'Submit request'
      end

      visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')
      expect(page).to have_text 'Login with Library ID/PIN'
    end
  end

  context 'with an aeon request' do
    let(:bib_data) { build(:sal3_as_holding) }

    it 'sends the user over to Aeon' do
      visit new_patron_request_path(instance_hrid: 'a12345', origin_location_code: 'SAL3-PAGE-AS')

      expect(page).to have_content 'On-site and digital access requests are managed by Aeon'
      expect(page).to have_button 'Continue to complete request'
    end
  end

  context 'with multiple items to pick from' do
    let(:bib_data) { build(:checkedout_holdings) }

    let(:current_user) { CurrentUser.new(username: user.sunetid, patron_key: user.patron_key, shibboleth: true, ldap_attributes:) }
    let(:ldap_attributes) { {} }

    before do
      allow(Settings.ils.patron_model.constantize).to receive(:find_by).with(patron_key: user.patron_key).and_return(patron)
      login_as(current_user)
    end

    it 'allows the user to page the available item' do
      visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')

      expect(page).to have_css 'h2', text: 'Select item(s)'
      check 'ABC 123'
      click_on 'Continue'
      expect do
        perform_enqueued_jobs do
          click_on 'Submit request'
        end
        expect(page).to have_content 'We received your pickup request'
      end.to change(PatronRequest, :count).by(1)

      expect(PatronRequest.last).to have_attributes(barcodes: ['12345678'])
    end

    it 'allows the user to hold/recall the checked out item' do
      visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')

      expect(page).to have_css 'h2', text: 'Select item(s)'
      check 'ABC 321'
      click_on 'Continue'
      choose 'Wait for a Stanford copy to become available'
      expect do
        perform_enqueued_jobs do
          click_on 'Submit request'
        end
        expect(page).to have_content 'We received your pickup request'
      end.to change(PatronRequest, :count).by(1)

      expect(PatronRequest.last).to have_attributes(barcodes: ['87654321'], fulfillment_type: 'hold')
    end

    it 'allows the user to select both items' do
      visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')

      expect(page).to have_css 'h2', text: 'Select item(s)'
      check 'ABC 123'
      check 'ABC 321'
      click_on 'Continue'
      choose 'Wait for a Stanford copy to become available'
      expect do
        perform_enqueued_jobs do
          click_on 'Submit request'
        end
        expect(page).to have_content 'We received your pickup request'
      end.to change(PatronRequest, :count).by(1)

      expect(PatronRequest.last).to have_attributes(barcodes: ['12345678', '87654321'], fulfillment_type: 'hold')
    end

    it 'filters down to a single form when barcode in parameters' do
      visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS', barcode: '12345678')

      expect(page).to have_no_css 'h2', text: 'Select item(s)'
      expect(page).to have_button 'Submit'
    end
  end

  context 'with an expired patron' do
    let(:current_user) { CurrentUser.new(username: user.sunetid, patron_key: user.patron_key, shibboleth: true, ldap_attributes:) }
    let(:patron) { build(:expired_patron) }
    let(:ldap_attributes) { {} }

    before do
      allow(Settings.ils.patron_model.constantize).to receive(:find_by).with(patron_key: user.patron_key).and_return(patron)
      login_as(current_user)
    end

    context 'for a scan-eligible item' do
      let(:bib_data) { build(:scannable_holdings) }
      let(:user) { create(:scan_eligible_user) }

      before do
        allow(current_user).to receive(:user_object).and_return(user)
        allow(Folio::Patron).to receive(:find_by).with(library_id: 'HOLD@GR').and_return(instance_double(Folio::Patron, id: 'hold-gr-uuid'))
      end

      it 'does not have the option to scan and places a request by a pseudopatron' do
        visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')

        expect(page).to have_no_text 'Email digital scan'
        check 'ABC 123'
        click_on 'Continue'
        expect do
          perform_enqueued_jobs do
            click_on 'Submit request'
          end
          expect(page).to have_content 'We received your pickup request!'
        end.to change(PatronRequest, :count).by(1)

        expect(PatronRequest.last).to have_attributes requester_patron_id: 'hold-gr-uuid'
      end
    end
  end
end

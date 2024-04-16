# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a page request' do
  include ActiveJob::TestHelper

  let(:user) { create(:sso_user) }
  let(:bib_data) { build(:single_holding) }
  let(:patron) do
    instance_double(Folio::Patron, id: user.patron_key, display_name: 'A User', exists?: true, email: nil,
                                   patron_description: 'faculty', visitor_patron?: false,
                                   patron_group_id: '503a81cd-6c26-400f-b620-14c08943697c',
                                   allowed_request_types: ['Hold', 'Recall'],
                                   ilb_eligible?: true, blocks: ['there is a block'])
  end

  before do
    stub_bib_data_json(bib_data)
  end

  context 'with an SSO user' do
    let(:current_user) { CurrentUser.new(username: user.sunetid, patron_key: user.patron_key, shibboleth: true) }

    before do
      allow(Settings.ils.patron_model.constantize).to receive(:find_by).with(patron_key: user.patron_key).and_return(patron)
      login_as(current_user)
    end

    it 'submits the request for pick-up at Green' do
      visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')
      click_on 'Log in with SUNet ID'

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
      click_on 'Log in with SUNet ID'

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
      click_on 'Log in with SUNet ID'

      perform_enqueued_jobs do
        click_on 'Submit'
      end

      expect(folio_client).to have_received(:create_circulation_request).with(have_attributes(requester_id: patron.id,
                                                                                              instance_id: bib_data.id))
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
        visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS')
        click_on 'Log in with SUNet ID'

        within '#earliestAvailableContainer' do
          expect(page).to have_content('Wednesday, Apr 3 2024, after 10am')
        end

        select 'Marine Biology Library', from: 'Preferred pickup location'
        within '#earliestAvailableContainer' do
          expect(page).to have_content('Friday, Apr 5 2024, after 4pm')
        end
      end
    end
  end

  context 'with a library ID user' do
    let(:stub_client) { FolioClient.new }
    let(:patron) do
      instance_double(Folio::Patron, id: 'some-lib-id-uuid', display_name: 'A User', exists?: true, email: nil,
                                     allowed_request_types: ['Hold'], visitor_patron?: false,
                                     patron_group_id: '985acbb9-f7a7-4f44-9b34-458c02a78fbc',
                                     patron_description: 'courtesy', ilb_eligible?: true, blocks: [])
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
      let(:bib_data) { build(:single_holding, items: [build(:item, effective_location: build(:law_location))]) }

      it 'goes to a dead-end page' do
        visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'LAW-STACKS1')
        first('summary').click

        fill_in 'Library ID', with: '12345'
        fill_in 'PIN', with: '54321'

        click_on 'Login'
        expect(page).to have_content('This item is not requestable at this time')
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
  end
end

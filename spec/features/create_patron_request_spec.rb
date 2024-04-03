# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a page request' do
  let(:user) { create(:sso_user) }
  let(:bib_data) { build(:single_holding) }
  let(:patron) do
    instance_double(Folio::Patron, id: user.patron_key, display_name: 'A User', exists?: true, email: nil,
                                   patron_group: { desc: 'faculty' },
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

      select 'Marine Biology Library', from: 'Pickup from'

      expect { click_on 'Submit' }.to change(PatronRequest, :count).by(1)

      expect(PatronRequest.last).to have_attributes(
        patron_id: user.patron_key,
        instance_hrid: 'a1234',
        origin_location_code: 'SAL3-STACKS',
        service_point_code: 'MARINE-BIO'
      )
    end
  end

  context 'with a library ID user' do
    let(:stub_client) { FolioClient.new }
    let(:patron) do
      instance_double(Folio::Patron, id: 'some-lib-id-uuid', display_name: 'A User', exists?: true, email: nil,
                                     patron_group: { desc: 'courtesy' }, ilb_eligible?: true, blocks: [])
    end

    before do
      allow(FolioClient).to receive(:new).and_return(stub_client)

      allow(stub_client).to receive(:login_by_library_id_and_pin).with('12345', '54321').and_return({ 'patronKey' => 'some-lib-id-uuid' })
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
  end
end
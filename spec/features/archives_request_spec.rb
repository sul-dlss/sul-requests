# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Requesting an item from an EAD', :js do
  before do
    allow(EadClient).to receive(:fetch).and_return(Ead::Document.new(eadxml))

    login_as(current_user)

    allow(AeonClient).to receive(:new).and_return(stub_aeon_client)

    allow(AeonClient.new).to receive_messages(reading_rooms: [instance_double(Aeon::ReadingRoom, id: 1, sites: ['SPECUA'])],
                                              available_appointments: [instance_double(Aeon::AvailableAppointment,
                                                                                       start_time: DateTime.new(2026, 2, 19),
                                                                                       maximum_appointment_length: 210.minutes)])
  end

  let(:user) { create(:sso_user) }
  let(:current_user) { CurrentUser.new(username: user.sunetid, patron_key: user.patron_key, shibboleth: true, ldap_attributes: {}) }

  let(:eadxml) do
    Nokogiri::XML(File.read('spec/fixtures/sc0097.xml')).tap(&:remove_namespaces!)
  end

  let(:aeon_user) { Aeon::User.new(username: user.email_address, auth_type: 'Default') }

  let(:stub_aeon_client) { instance_double(AeonClient, find_user: aeon_user, create_request: { success: true }) }

  it 'allows the user to submit a request for an item from an EAD' do
    visit new_archives_request_path(value: 'http://example.com/ead.xml')

    expect(page).to have_content('New request')
    expect(page).to have_content('Knuth (Donald E.) papers')

    choose 'Reading room appointment'

    expect(page).to have_content('Earliest appointment available: Thursday, Feb 19, 2026')

    click_button 'Continue'

    click_link 'Computers and Typesetting'
    click_link 'Legal size documents'

    check 'Box 12'
    click_button 'Continue'

    # In the Appointment step
    click_button 'Continue'

    # In the (temporary) review step
    click_button 'Submit to Aeon'

    expect(page).to have_content('All 1 request(s) submitted successfully!')

    expect(stub_aeon_client).to have_received(:create_request).with(an_object_having_attributes(
                                                                      username: user.email_address,
                                                                      call_number: 'SC0097 Computers and Typesetting',
                                                                      item_volume: 'Box 12',
                                                                      site: 'SPECUA'
                                                                    ))
  end

  context 'with a digitization request' do
    it 'allows the user to submit a request with details about the portion of the item to be digitized' do # rubocop:disable RSpec/ExampleLength
      visit new_archives_request_path(value: 'http://example.com/ead.xml')

      expect(page).to have_content('New request')
      expect(page).to have_content('Knuth (Donald E.) papers')

      choose 'Digitization'

      click_button 'Continue'

      click_link 'Computers and Typesetting'
      click_link 'Legal size documents'
      check 'Box 12'
      click_button 'Continue'

      click_button 'Box 12'
      fill_in 'Requested pages', with: 'Pages 1-10'
      fill_in 'Additional information', with: 'Testing only'
      click_button 'Continue'

      check 'I agree to these terms'
      click_button 'Continue'

      click_button 'Submit to Aeon'

      expect(page).to have_content('All 1 request(s) submitted successfully!')
      expect(stub_aeon_client).to have_received(:create_request).with(an_object_having_attributes(
                                                                        username: user.email_address,
                                                                        item_info5: 'Pages 1-10',
                                                                        item_volume: 'Box 12',
                                                                        special_request: 'Testing only',
                                                                        call_number: 'SC0097 Computers and Typesetting',
                                                                        site: 'SPECUA'
                                                                      ))
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating an Aeon patron request', :js do
  let(:user) { create(:sso_user) }
  let(:current_user) { CurrentUser.new(username: user.sunetid, patron_key: user.patron_key, shibboleth: true) }
  let(:folio_instance) { :special_collections_single_holding }
  let(:patron) do
    instance_double(Folio::Patron, id: user.patron_key, username: 'auser', display_name: 'A User', exists?: true, email: nil,
                                   patron_description: 'faculty',
                                   patron_group_name: 'faculty',
                                   blocked?: false, proxies: [], sponsors: [], sponsor?: false, proxy?: false,
                                   allowed_request_types: ['Hold', 'Recall', 'Page'])
  end

  before do
    allow(Folio::Patron).to receive(:find_by).with(patron_key: user.patron_key).and_return(patron)
    login_as(current_user)
    stub_folio_instance_json(build(folio_instance))

    allow(AeonClient).to receive(:new).and_return(stub_aeon_client)

    stub_request(:head, 'https://archives.stanford.edu/findingaid/ark:/22236/s1060cff19-35d7-4ca7-83cc-37009f6324b8')
      .to_return(status: 302, headers: { 'Location' => 'https://archives.stanford.edu/catalog/fake' })
    stub_request(:head, 'https://archives.stanford.edu/catalog/fake').to_return(status: 200)

    allow(EadClient).to receive(:fetch).and_return(Ead::Document.new(eadxml, url: 'whatever'))
  end

  let(:folio_instance) { :special_collections_finding_aid_holdings }
  let(:aeon_user) { Aeon::User.new(username: user.email_address, auth_type: 'Default') }

  let(:reading_rooms) { JSON.load_file('spec/fixtures/reading_rooms.json').map { |room| Aeon::ReadingRoom.from_dynamic(room) } }
  let(:stub_aeon_client) do
    instance_double(AeonClient, find_user: aeon_user, reading_rooms:, appointments_for: [], available_appointments: [],
                                activities: [])
  end
  let(:eadxml) do
    Nokogiri::XML(File.read('spec/fixtures/sc0097.xml')).tap(&:remove_namespaces!)
  end

  it 'redirects the user to the EAD request form' do
    visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SPEC-STACKS')

    expect(page).to have_text 'View in Archival Collections at Stanford'
    expect(page).to have_text 'Knuth (Donald E.) papers'
  end
end

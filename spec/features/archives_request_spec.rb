# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Requesting an item from an EAD', :js do
  before do
    allow(EadClient).to receive(:fetch).and_return(Ead::Document.new(eadxml))

    login_as(current_user)

    allow(AeonClient).to receive(:new).and_return(stub_aeon_client)
  end

  let(:user) { create(:sso_user) }
  let(:current_user) { CurrentUser.new(username: user.sunetid, patron_key: user.patron_key, shibboleth: true, ldap_attributes: {}) }

  let(:eadxml) do
    Nokogiri::XML(File.read('spec/fixtures/sc0097.xml')).tap(&:remove_namespaces!)
  end

  let(:stub_aeon_client) { instance_double(AeonClient, create_request: { success: true }) }

  it 'allows the user to submit a request for an item from an EAD' do
    visit new_archives_request_path(value: 'http://example.com/ead.xml')

    expect(page).to have_content('New request')
    expect(page).to have_content('Knuth (Donald E.) papers')

    choose 'Reading room appointment'
    click_button 'Continue'

    click_link 'Computers and Typesetting'
    check 'Box 12'
    click_button 'Continue'

    click_button 'Submit to Aeon'

    expect(page).to have_content('All 1 request(s) submitted successfully!')

    expect(stub_aeon_client).to have_received(:create_request).with(an_object_having_attributes(
                                                                      username: user.email_address,
                                                                      call_number: 'SC0097 Computers and Typesetting',
                                                                      site: 'SPECUA'
                                                                    ))
  end
end

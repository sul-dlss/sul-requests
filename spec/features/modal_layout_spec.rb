# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Modal Layout' do
  before do
    allow_any_instance_of(FolioClient).to receive(:find_instance).and_return({ title: 'Test title' })
    allow_any_instance_of(FolioClient).to receive(:resolve_to_instance_id).and_return('f1c52ab3-721e-5234-9a00-1023e034e2e8')
    stub_folio_holdings(:folio_sal3_multiple_holdings)
    stub_searchworks_api_json(build(:sal3_holdings))
  end

  it 'is not used when the modal param is not set' do
    visit new_request_path(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS')

    expect(page).to have_css('#su-wrap')
  end

  it 'is used when the modal param is passed by the form and redirects' do
    stub_current_user(create(:sso_user))
    visit new_request_path(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS', modal: true)

    expect(page).not_to have_css('#su-wrap')

    click_link 'Request & pickup'

    expect(page).not_to have_css('#su-wrap')
    expect(current_url).to match(/modal=true/)

    expect(page).to have_css('input[name="modal"]', visible: :hidden)

    first(:button, 'Send request').click

    expect(page).not_to have_css('#su-wrap')
    expect(current_url).to match(/modal=true/)
  end
end

require 'rails_helper'

describe 'Modal Layout' do
  before { stub_searchworks_api_json(build(:sal3_holdings)) }

  it 'is not used when the modal param is not set' do
    visit new_request_path(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS')

    expect(page).to have_css('#su-wrap')
  end

  it 'is used when the modal param is passed by the form and redirects' do
    stub_current_user(create(:webauth_user))
    visit new_request_path(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS', modal: true)

    expect(page).to_not have_css('#su-wrap')

    click_link 'Deliver to campus library'

    expect(page).to_not have_css('#su-wrap')
    expect(current_url).to match(/modal=true/)

    expect(page).to have_css('input[name="modal"]')

    first(:button, 'Send request').click

    expect(page).to_not have_css('#su-wrap')
    expect(current_url).to match(/modal=true/)
  end
end

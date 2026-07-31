# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Mediated requests' do
  let(:patron) do
    build(:sponsor_patron)
  end

  let(:current_user) do
    CurrentUser.new(username: 'stub_user', patron_key: 'ec52d62d-9f0e-4ea5-856f-a1accb0121d1', shibboleth: true)
  end

  let(:user) do
    current_user.user_object
  end

  before do
    create(
      :mediated_patron_request_with_holdings,
      patron_request_items_attributes: [
        { item_id: '12345678', item_callnumber: 'Test Call Number' },
        { item_id: '23456789' }
      ],
      created_at: 1.day.ago,
      needed_date: 3.days.from_now,
      user: user,
      instance_author: 'Test Author',
      instance_document_type: 'Book'
    )

    login_as(current_user)
  end

  it 'has mediated request data' do
    visit mediated_requests_path

    expect(page).to have_text(/Restricted to in-library use only/)
    expect(page).to have_text 'Pending staff review/approval'
  end

  it 'allows the user to cancel a mediated request', :js do
    visit mediated_requests_path

    click_on 'Cancel'
    click_on 'Yes - Delete'

    expect(page).to have_no_text(/Restricted to in-library use only/)
    expect(PatronRequest.last.reload).to have_attributes(request_type: 'cancelled')
  end
end

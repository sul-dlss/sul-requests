# frozen_string_literal: true

require 'rails_helper'

# Since we need to redirect through Illiad on POST and the rails test harness does
# not follow redirects we can't test via the form that the requests are going through.
# Our controller tests are going to have to be sufficient where we test that we redirect
# to the illiad URL passing the create scan URL via GET and that the create scan URL via GET works.
RSpec.describe 'Create Scan Request' do
  let(:selected_items) do
    [
      double(:item, barcode: '12345678', type: 'STKS', callnumber: 'ABC 123', checked_out?: false, hold?: false, missing?: false,
                    processing?: false, hold_recallable?: false)
    ]
  end

  before do
    allow(Settings.ils.bib_model.constantize).to receive(:new).and_return(double(:bib_data, title: 'Test title'))
    allow(HoldingsRelationshipBuilder).to receive(:build).and_return(selected_items)
    allow(SubmitScanRequestJob).to receive(:perform_later)
    stub_bib_data_json(:sal3_holdings)
  end

  it 'does not display a destination pickup' do
    stub_current_user(create(:sso_user))

    visit new_scan_path(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS')

    expect(page).not_to have_select('request_destination')
    expect(page).not_to have_content('Deliver to')
  end

  it 'does not include the highlighted section around destination and needed date' do
    stub_current_user(create(:sso_user))

    visit new_scan_path(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS')

    expect(page).not_to have_css('.alert-warning.destination-note-callout')
  end

  describe 'by an eligible SSO user' do
    before do
      stub_current_user(create(:scan_eligible_user))
    end

    it 'displays a copyright restrictions notice in a collapse' do
      visit new_scan_path(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS')

      expect(page).to have_content 'Notice concerning copyright restrictions'
      expect(page).to have_content 'The copyright law of the United States'
    end
  end

  describe 'by non SSO user' do
    it 'provides a link to page the item' do
      visit new_scan_path(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS')

      expect(page).to have_link 'Request the physical item'

      click_link 'Request the physical item'

      expect(page).to have_css('h1#dialogTitle', text: 'Request & pickup service')
      expect(current_url).to eq new_page_url(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS')
    end
  end
end

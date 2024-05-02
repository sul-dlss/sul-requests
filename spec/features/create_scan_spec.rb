# frozen_string_literal: true

require 'rails_helper'

# Since we need to redirect through Illiad on POST and the rails test harness does
# not follow redirects we can't test via the form that the requests are going through.
# Our controller tests are going to have to be sufficient where we test that we redirect
# to the illiad URL passing the create scan URL via GET and that the create scan URL via GET works.
RSpec.describe 'Create Scan Request' do
  before do
    allow(SubmitIlliadRequestJob).to receive(:perform_later).and_return(instance_double(SubmitIlliadRequestJob))
    stub_bib_data_json(build(:scannable_holdings))
  end

  it 'does not display a destination pickup' do
    stub_current_user(create(:sso_user))

    visit new_scan_path(item_id: '12345', origin: 'SAL3', origin_location: 'SAL3-STACKS')

    expect(page).to have_no_select('request_destination')
    expect(page).to have_no_content('Deliver to')
  end

  it 'does not include the highlighted section around destination and needed date' do
    stub_current_user(create(:sso_user))

    visit new_scan_path(item_id: '12345', origin: 'SAL3', origin_location: 'SAL3-STACKS')

    expect(page).to have_no_css('.alert-warning.destination-note-callout')
  end

  describe 'by an eligible SSO user' do
    let(:patron) { build(:pilot_group_patron) }
    let(:user) { create(:scan_eligible_user) }

    before do
      stub_current_user(user)
      allow(user).to receive(:patron).and_return(patron)
    end

    it 'displays a copyright restrictions notice in a collapse', :js do
      visit new_scan_path(item_id: '12345', origin: 'SAL3', origin_location: 'SAL3-STACKS')

      expect(page).to have_content 'Copyright notice'
      expect(page).to have_content 'The copyright law of the United States'

      choose 'ABC 123 Available'
      fill_in 'Title of article or chapter', with: 'Chapter 1'
      click_on 'Send request'

      expect(page).to have_css('h1#dialogTitle', text: /We're working on it/)
      expect(page).to have_css('dl.user-contact-information p.help-block',
                               text: "(We'll send a copy of this request to your email.)")
      expect(page).to have_css('h2', text: 'SAL Item Title')

      expect(page).to have_css('dt', text: 'DELIVER TO')
      expect(page).to have_css('dd', text: 'SCAN')

      expect(page).to have_content('some-eligible-user@stanford.edu')
    end
  end

  describe 'by non SSO user' do
    it 'provides a link to page the item' do
      visit new_scan_path(item_id: '12345', origin: 'SAL3', origin_location: 'SAL3-STACKS')

      expect(page).to have_link 'Request the physical item'

      click_on 'Request the physical item'

      expect(page).to have_css('h1#dialogTitle', text: 'Request & pickup service')
      expect(current_url).to eq new_page_url(item_id: '12345', origin: 'SAL3', origin_location: 'SAL3-STACKS')
    end
  end
end

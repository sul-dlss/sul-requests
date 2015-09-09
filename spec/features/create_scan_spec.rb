require 'rails_helper'

# Since we need to redirect through Illiad on POST and the rails test harness does
# not follow redirects we can't test via the form that the requests are going through.
# Our controller tests are going to have to be sufficient where we test that we redirect
# to the illiad URL passing the create scan URL via GET and that the create scan URL via GET works.
describe 'Create Scan Request' do
  before do
    allow_any_instance_of(ScansController).to receive(:illiad_url).and_return('http://illiad.ill')
    stub_searchworks_api_json(build(:sal3_holdings))
  end

  it 'does not display a destination pickup' do
    stub_current_user(create(:webauth_user))

    visit new_scan_path(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS')

    expect(page).to_not have_select('request_destination')
    expect(page).to_not have_content('Deliver to')
  end

  describe 'by an eligible webauth user' do
    before do
      stub_current_user(create(:scan_eligible_user))
    end

    it 'should display a copyright restrictions notice in a collapse' do
      visit new_scan_path(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS')

      expect(page).to have_content 'Notice concerning copyright restrictions'

      click_on 'Notice concerning copyright restrictions'

      expect(page).to have_content 'The copyright law of the United States'
    end
  end
  describe 'by non webauth user' do
    it 'should provide a link to page the item' do
      visit new_scan_path(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS')

      expect(page).to have_link 'Request the physical item'

      click_link 'Request the physical item'

      expect(page).to have_css('h1#dialogTitle', 'Request delivery to campus library')
      expect(current_url).to eq new_page_url(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS')
    end
  end
end

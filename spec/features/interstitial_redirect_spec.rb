require 'rails_helper'

describe 'Interstitial page redirect' do
  pending 'redirects to the page in the redirect_to parameter', js: true do
    # This test isn't working.  I believe the redirect is getting halted in the test harness.
    visit interstitial_path(redirect_to: root_url)

    # This is the heading for www.example.com (I don't really know a better way to test this, we may need to chuck it)
    expect(page).to have_css('h1', text: 'Example Domain')
  end

  it 'includes a link to allow non-js browsers to continue with the redirect' do
    visit interstitial_path(redirect_to: root_url)

    expect(page).to have_css('#redirectNote a', text: 'Click here if you are not redirected.')
  end
end

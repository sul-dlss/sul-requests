# frozen_string_literal: true

require 'rails_helper'

describe 'Eligibility Validation' do
  let(:user) { create(:webauth_user) }

  before do
    expect(Settings.features).to receive(:validate_eligibility).and_return(true)
    stub_current_user(user)
  end

  context 'when the user making the request has an eligible affiliation' do
    before do
      user.affiliation = 'stanford:student'
    end

    it 'allows the request to be submitted' do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')
      first(:button, 'Send request').click

      expect(current_url).to eq successful_page_url(Page.last)
      expect_to_be_on_success_page
    end
  end

  context 'when the user making the request does not have an eligible affiliation' do
    before do
      user.affiliation = 'stanford:affiliate:sponsored'
    end

    it 'allows the request to be submitted' do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')
      first(:button, 'Send request').click

      expect(current_url).to eq ineligible_requests_url
      expect(page).to have_css('h1#dialogTitle', text: /Sorry, we can't fulfill your request/)
      expect(Page.last).to be_nil
    end
  end
end

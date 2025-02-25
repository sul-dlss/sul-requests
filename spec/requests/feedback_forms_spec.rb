# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'The feedback form', type: :feature do
  let(:current_user?) { false }
  let(:user) { create(:sso_user) }

  context 'when not logged in' do
    it 'reCAPTCHA challenge is present' do
      visit root_path
      expect(page).to have_css '.requests-captcha'
    end
  end

  context 'without js' do
    before do
      stub_current_user(user)
    end

    it 'reCAPTCHA challenge is NOT present' do
      visit root_path
      expect(page).to have_no_css '.requests-captcha'
    end

    # TODO_SW_2024: Wait for page after homepage to be created to add
    # it 'feedback form should be shown filled out and submitted' do
    #   visit new_patron_request_path({'instance_hrid' => '1234', 'origin_location_code' => 'SAL3'})
    #   click_on 'Feedback'
    #   expect(page).to have_css('#feedback-form', visible: :visible)
    #   expect(page).to have_link 'Cancel'
    #   within 'form.feedback-form' do
    #     fill_in('message', with: 'This is only a test')
    #     fill_in('name', with: 'Ronald McDonald')
    #     fill_in('to', with: 'test@kittenz.eu')
    #     click_on 'Send'
    #   end
    #   puts page.inspect
    #   expect(page).to have_css('div.alert-success', text: 'Thank you! Your feedback has been sent.')
    # end
  end
end

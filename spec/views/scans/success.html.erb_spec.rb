# frozen_string_literal: true

require 'rails_helper'

describe 'scans/success.html.erb' do
  let(:user) { create(:webauth_user) }
  let(:request) { create(:scan, user: user) }

  before do
    allow(view).to receive_messages(current_request: request)
    allow(view).to receive_messages(current_user: user)
    stub_template 'scans/_searchworks_item_information.html.erb' => ''
  end

  describe 'symphony contacted' do
    it 'has completion text and icon for completed requests' do
      render
      expect(rendered).to have_css('.sul-i-check-2')
      expect(rendered).to have_css('h1', text: /Request complete/)
    end

    it 'omits the user contact info if the symphony response failed to indicate success' do
      render
      expect(rendered).not_to have_css('dl.user-contact-information span.requested-by')
    end
  end

  describe 'successful symphony response' do
    let(:symphony_response) { build(:symphony_scan_success) }
    let(:request) { create(:scan, user: user, symphony_response_data: symphony_response) }

    it 'has correctly styled user email address and explanation text' do
      help_block_text = "(We've sent a copy of this request to your email.)"

      render
      expect(rendered).to have_css('dl.user-contact-information span.requested-by', text: user.to_email_string)
      expect(rendered).to have_css('dl.user-contact-information p.help-block', text: help_block_text)
    end
  end
end

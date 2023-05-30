# frozen_string_literal: true

require 'rails_helper'

describe 'scans/success.html.erb' do
  let(:user) { create(:sso_user) }
  let(:request) { create(:scan, user:) }

  before do
    allow(view).to receive_messages(current_request: request)
    allow(view).to receive_messages(current_user: user)
    stub_template 'scans/_searchworks_item_information.html.erb' => ''
  end

  it 'has text indicating that the request is in process' do
    render
    expect(rendered).to have_css('h1', text: /We're working on it/)
  end

  it 'includes the user contact info' do
    render
    expect(rendered).to have_css('dl.user-contact-information span.requested-by', text: user.to_email_string)
  end

  it 'has correctly styled user email address and explanation text' do
    help_block_text = "(We'll send a copy of this request to your email.)"
    render

    expect(rendered).to have_css('dl.user-contact-information p.help-block', text: help_block_text)
  end
end

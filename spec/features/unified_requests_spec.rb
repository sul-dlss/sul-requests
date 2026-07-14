# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Request Page', :js do
  use_stub_aeon_client
  let(:user) { create(:sso_user) }
  let(:current_user) { CurrentUser.new(username: user.sunetid, shibboleth: true) }

  before do
    login_as(current_user)
  end

  it 'loads the page and clears all the visible placeholders' do
    visit unified_requests_path

    expect(page).to have_text('Submitted requests')
    expect(page).to have_no_css('.placeholder-glow')
  end
end

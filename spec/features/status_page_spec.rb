require 'rails_helper'

describe 'Status Page' do
  let(:request) { create(:mediated_page, user: user) }
  before do
    stub_current_user(user)
  end

  describe 'by webuath users' do
    let(:user) { create(:webauth_user) }
    it 'is available' do
      visit status_mediated_page_path(request)

      expect(page).to have_css('h1', text: 'Status of your request')
      expect(page).to have_css('h2', text: request.item_title)

      expect(page).to have_css('dt', text: 'Requested on')
      expect(page).to have_css('dt', text: 'Must be used in')
    end
  end

  describe 'by users with tokens' do
    let(:user) { create(:library_id_user) }
    it 'is available' do
      visit status_mediated_page_path(request, token: request.encrypted_token)

      expect(page).to have_css('h1', text: 'Status of your request')
      expect(page).to have_css('h2', text: request.item_title)

      expect(page).to have_css('dt', text: 'Requested on')
      expect(page).to have_css('dt', text: 'Must be used in')
    end
  end
end

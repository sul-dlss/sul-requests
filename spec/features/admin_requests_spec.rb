require 'rails_helper'

describe 'Viewing all requests' do
  describe 'by a superadmin user' do
    before do
      stub_current_user(create(:superadmin_user))
      create(:page, item_id: 2345)
      create(:page, item_id: 2346, origin: 'SAL-NEWARK')
    end
    it 'should list data in tables' do
      visit admin_index_path

      expect(page).to have_css('h3', text: /Green Library/)
      expect(page).to have_css('h4', text: /Library=GREEN & location=STACKS/)
      expect(page).to have_css('td', text: '2345')

      expect(page).to have_css('h3', text: /SAL Newark/)
      expect(page).to have_css('h4', text: /Library=SAL-NEWARK & location=STACKS/)
      expect(page).to have_css('td', text: '2346')

      expect(page).to have_selector('td', text: 'Page', count: 2)
      expect(page).to have_selector('table.table-striped', count: 2)
    end
  end
end

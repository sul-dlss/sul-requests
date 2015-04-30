require 'rails_helper'

describe 'Viewing all requests' do
  describe 'by a superadmin user' do
    before do
      stub_current_user(create(:superadmin_user))
      create(:page, item_id: 2345, item_title: 'Fourth symphony. [Op. 51].',
                    user: User.create(webauth: 'jstanford'))
      create(:page, item_id: 2346, item_title: 'An American in Paris', origin: 'SAL-NEWARK',
                    user: User.create(name: 'Joe', email: 'joe@xyz.com'))
    end
    it 'should list data in tables' do
      visit admin_index_path

      expect(page).to have_css('h3', text: /Green Library/)
      expect(page).to have_css('h4', text: /Library=GREEN & location=STACKS/)
      expect(page).to have_css('td', text: '2345')
      expect(page).to have_css('td', text: /Fourth symphony. \[Op. 51\]./)
      expect(page).to have_css('td a[href="mailto:jstanford@stanford.edu"]', text: /jstanford@stanford.edu/)

      expect(page).to have_css('h3', text: /SAL Newark/)
      expect(page).to have_css('h4', text: /Library=SAL-NEWARK & location=STACKS/)
      expect(page).to have_css('td', text: '2346')
      expect(page).to have_css('td', text: /An American in Paris/)
      expect(page).to have_css('td a[href="mailto:joe@xyz.com"]', text: /Joe \(joe@xyz.com\)/)

      expect(page).to have_selector('td', text: /^Page$/, count: 2)
      expect(page).to have_selector('table.table-striped', count: 2)
    end
  end
end

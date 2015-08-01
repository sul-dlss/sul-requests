require 'rails_helper'

describe 'Viewing all requests' do
  describe 'index' do
    describe 'by a superadmin user' do
      before do
        stub_current_user(create(:superadmin_user))
        create(:page, item_id: 2345, item_title: 'Fourth symphony. [Op. 51].',
                      user: User.create(webauth: 'jstanford'))
        create(:page, item_id: 2346,
                      item_title: 'An American in Paris',
                      origin: 'SAL-NEWARK',
                      request_comment: 'I can has this item?',
                      user: User.create(name: 'Joe', email: 'joe@xyz.com')
              )
      end
      it 'should list data in tables' do
        visit admin_index_path

        expect(page).to have_css('h2', text: /Green Library/)
        expect(page).to have_css('td a', text: 'Fourth symphony. [Op. 51].')
        expect(page).to have_css('td a[href="mailto:jstanford@stanford.edu"]', text: /jstanford@stanford.edu/)

        expect(page).to have_css('h2', text: /SAL Newark/)
        expect(page).to have_css('td a', text: 'An American in Paris')
        expect(page).to have_css('td a[href="mailto:joe@xyz.com"]', text: /Joe \(joe@xyz.com\)/)
        expect(page).to have_css('td', text: 'I can has this item?')

        expect(page).to have_selector('table.table-striped', count: 2)
      end
    end

    describe 'by an anonmyous user' do
      before { stub_current_user(create(:anon_user)) }

      it 'should raise an error' do
        expect(
          -> { visit admin_index_path }
        ).to raise_error(CanCan::AccessDenied)
      end
    end
  end

  describe 'show' do
    describe 'by a superadmin' do
      before do
        stub_current_user(create(:superadmin_user))
        create(:mediated_page)
        create(:mediated_page)
        create(:hoover_mediated_page)
      end

      it 'should list all the medated pages for the given library' do
        visit admin_path('SPEC-COLL')

        expect(page).to have_css('h2', text: 'Special Collections')

        expect(page).to have_css('table tbody tr', count: 2)

        visit admin_path('HOOVER')

        expect(page).to have_css('h2', text: 'Hoover Library')

        expect(page).to have_css('table tbody tr', count: 1)
      end

      it 'paginates the data' do
        visit admin_path('SPEC-COLL', per_page: 1)

        expect(page).to have_css('.pagination')

        click_on 'Next ›'

        expect(page).to have_selector('.pagination .disabled', text: 'Next ›')
      end

      it 'allows the user to toggle between expired and active mediated pages' do
        create(:mediated_page, needed_date: Time.zone.today - 3.days)
        create(:mediated_page, needed_date: Time.zone.today - 2.days)
        create(:mediated_page, needed_date: Time.zone.today - 1.days)
        visit admin_path('SPEC-COLL')

        expect(page).to have_css('tbody tr', count: 2)
        expect(page).to have_css('a', text: 'Show archived requests')
        click_link 'Show archived requests'

        expect(page).to have_css('tbody tr', count: 3)
        expect(page).to have_css('a', text: 'Show current requests')
        click_link 'Show current requests'

        expect(page).to have_css('tbody tr', count: 2)
        expect(page).to have_css('a', text: 'Show archived requests')
      end
    end
  end

  describe 'by an anonmyous user' do
    before { stub_current_user(create(:anon_user)) }

    it 'should raise an error' do
      expect(
        -> { visit admin_path('SPEC-COLL') }
      ).to raise_error(CanCan::AccessDenied)
    end
  end
end

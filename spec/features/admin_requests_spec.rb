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
      it 'should list data in a table' do
        visit admin_index_path

        expect(page).to have_css('td a[data-behavior="truncate"]', text: 'Fourth symphony. [Op. 51].')
        expect(page).to have_css('td a[href="mailto:jstanford@stanford.edu"]', text: /jstanford@stanford.edu/)

        expect(page).to have_css('td a[data-behavior="truncate"]', text: 'An American in Paris')
        expect(page).to have_css('td a[href="mailto:joe@xyz.com"]', text: /Joe \(joe@xyz.com\)/)

        expect(page).to have_selector('table.table-striped', count: 1)
      end
    end

    describe 'by an anonmyous user' do
      before { stub_current_user(create(:anon_user)) }

      it 'should redirect to the login page' do
        expect_any_instance_of(AdminController).to receive(:redirect_to).with(
          login_path(referrer: admin_index_url)
        )
        visit admin_index_path
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

      it 'should list all the mediated pages for the given library' do
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
        build(:mediated_page, needed_date: Time.zone.today - 3.days).save(validate: false)
        build(:mediated_page, needed_date: Time.zone.today - 2.days).save(validate: false)
        build(:mediated_page, needed_date: Time.zone.today - 1.day).save(validate: false)
        visit admin_path('SPEC-COLL')

        expect(page).to have_css('tbody tr', count: 2)
        expect(page).to have_css('a', text: 'Show archived requests')
        click_link 'Show archived requests'

        expect(page).to have_css('h2', text: 'Special Collections archived requests')
        expect(page).to have_css('tbody tr', count: 3)
        expect(page).to have_css('a', text: 'Show current requests')
        click_link 'Show current requests'

        expect(page).to have_css('h2', text: 'Special Collections')
        expect(page).to have_css('tbody tr', count: 2)
        expect(page).to have_css('a', text: 'Show archived requests')
      end

      context 'with an ad-hoc item' do
        it 'works' do
          create(:mediated_page, ad_hoc_items: ['ZZZ-123'],
                                 origin: 'SPEC-COLL',
                                 request_comment: 'I can has this unbarcoded item?',
                                 user: User.create(name: 'Jane', email: 'jane@example.com')
                )

          visit admin_path('SPEC-COLL')

          expect(page).to have_css('td', text: 'I can has this unbarcoded item?')
        end
      end
    end
  end

  describe 'by an anonymous user' do
    before { stub_current_user(create(:anon_user)) }

    it 'should redirect to the login page' do
      expect_any_instance_of(AdminController).to receive(:redirect_to).with(
        login_path(referrer: admin_url('SPEC-COLL'))
      )
      visit admin_path('SPEC-COLL')
    end
  end
end

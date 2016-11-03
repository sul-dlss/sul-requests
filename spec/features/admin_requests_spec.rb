require 'rails_helper'

describe 'Viewing all requests' do
  describe 'index' do
    describe 'by a superadmin user' do
      before do
        stub_current_user(create(:superadmin_user))
        create(:page, item_id: 2345, item_title: 'Fourth symphony. [Op. 51].',
                      user: User.create(webauth: 'jstanford', email: 'jstanford@stanford.edu'))
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
        create(:hoover_archive_mediated_page)
      end

      it 'should list all the mediated pages for the given library' do
        visit admin_path('SPEC-COLL')

        expect(page).to have_css('h2', text: 'Special Collections')

        expect(page).to have_css('table tbody tr', count: 2)

        visit admin_path('HV-ARCHIVE')

        expect(page).to have_css('h2', text: 'Hoover Archive')

        expect(page).to have_css('table tbody tr', count: 1)
      end

      describe 'pagination' do
        context 'on the "All pending" page' do
          before { visit admin_path('SPEC-COLL', per_page: 1) }

          it 'requests are not paginated' do
            expect(page).not_to have_css('.pagination')
          end
        end

        context 'on the "All done" page' do
          before do
            MediatedPage.all.map(&:approved!)
            visit admin_path('SPEC-COLL', done: 'true', per_page: 1)
          end

          it 'requests are paginated', js: true do
            expect(page).to have_css('.pagination')

            click_on 'Next ›'

            expect(page).to have_selector('.pagination .disabled', text: 'Next ›')
          end
        end
      end

      it 'allows the user to toggle between expired and active mediated pages (and updates button class)' do
        build(:mediated_page, approval_status: :approved, needed_date: Time.zone.today - 3.days).save(validate: false)
        build(:mediated_page, approval_status: :approved, needed_date: Time.zone.today - 2.days).save(validate: false)
        build(:mediated_page, approval_status: :approved, needed_date: Time.zone.today - 1.day).save(validate: false)
        visit admin_path('SPEC-COLL')

        expect(page).to have_css('tbody tr', count: 2)
        expect(page).to have_css('a.btn-primary', text: 'All pending')

        expect(page).to have_css('a', text: 'All done')
        expect(page).not_to have_css('a.btn-primary', text: 'All done')
        click_link 'All done'

        expect(page).to have_css('h2', text: 'Special Collections')
        expect(page).to have_css('tbody tr', count: 3)
        expect(page).to have_css('a.btn-primary', text: 'All done')
        expect(page).to have_css('a', text: 'All pending')
        expect(page).not_to have_css('a.btn-primary', text: 'All pending')

        click_link 'All pending'

        expect(page).to have_css('h2', text: 'Special Collections')
        expect(page).to have_css('tbody tr', count: 2)
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

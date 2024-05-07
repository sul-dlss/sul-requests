# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Viewing all requests' do
  describe 'index' do
    describe 'by a superadmin user' do
      before do
        stub_current_user(create(:superadmin_user))
        create(:page, item_id: 2345, item_title: 'Fourth symphony. [Op. 51].',
                      user: User.create(sunetid: 'jstanford', email: 'jstanford@stanford.edu'))
        create(:page, item_id: 2346,
                      item_title: 'An American in Paris',
                      request_comment: 'I can has this item?',
                      user: User.create(name: 'Joe', email: 'joe@xyz.com')
              )
        create(:mediated_page, item_title: 'I am Mediated',
                               origin: 'ART',
                               request_comment: 'I can has this mediated item?',
                               user: User.create(name: 'Jane', email: 'jane@example.com')
              )
      end

      it 'lists data in a table' do
        visit old_requests_path

        expect(page).to have_css('td a[data-behavior="truncate"]', text: 'Fourth symphony. [Op. 51].')
        expect(page).to have_css('td a[href="mailto:jstanford@stanford.edu"]', text: /jstanford@stanford.edu/)

        expect(page).to have_css('td a[data-behavior="truncate"]', text: 'An American in Paris')
        expect(page).to have_css('td a[href="mailto:joe@xyz.com"]', text: /Joe \(joe@xyz.com\)/)

        expect(page).to have_css('td a[data-behavior="truncate"]', text: 'I am Mediated')
        expect(page).to have_css('td a[href="mailto:jane@example.com"]', text: /Jane \(jane@example.com\)/)

        expect(page).to have_css('table.table-striped', count: 1)

        expect(page).to have_css('th.col-1', text: 'Type')
        expect(page).to have_css('th.col-1', text: 'Origin')
        expect(page).to have_css('th.col-1', text: 'Destination')
        expect(page).to have_css('th.col-5', text: 'Title')
        expect(page).to have_css('th.col-2', text: 'Requester')
        expect(page).to have_css('th.col-1', text: 'Requested on')
        expect(page).to have_css('th.col-1', text: 'Status')
      end

      it 'allows filtering by request type' do
        visit old_requests_path

        expect(page).to have_css('td a', text: 'Mediated pages')
        expect(page).to have_css('td a', text: 'Pages')

        click_on 'Mediated pages'

        expect(page).to have_css('td', text: 'Mediated pages [x]')
        expect(page).to have_css('td a', text: 'Pages')

        expect(page).to have_no_css('td a[data-behavior="truncate"]', text: 'An American in Paris')
        expect(page).to have_no_css('td a[href="mailto:joe@xyz.com"]', text: /Joe \(joe@xyz.com\)/)

        expect(page).to have_css('td a[data-behavior="truncate"]', text: 'I am Mediated')
        expect(page).to have_css('td a[href="mailto:jane@example.com"]', text: /Jane \(jane@example.com\)/)

        click_on 'Pages'

        expect(page).to have_css('td a', text: 'Mediated pages')
        expect(page).to have_css('td', text: 'Pages [x]')

        expect(page).to have_css('td a[data-behavior="truncate"]', text: 'An American in Paris')
        expect(page).to have_css('td a[href="mailto:joe@xyz.com"]', text: /Joe \(joe@xyz.com\)/)

        expect(page).to have_no_css('td a[data-behavior="truncate"]', text: 'I am Mediated')
        expect(page).to have_no_css('td a[href="mailto:jane@example.com"]', text: /Jane \(jane@example.com\)/)

        click_on '[x]'

        expect(page).to have_css('td a', text: 'Mediated pages')
        expect(page).to have_css('td a', text: 'Pages')
      end

      context 'filter by create date' do
        yesterday = Time.zone.today - 1.day
        let(:today_s) { Time.zone.today.to_s }

        before do
          create(:page_mp_mediated_page, created_at: yesterday)
          create(:page, created_at: yesterday)
          visit old_requests_path
          fill_in(:created_at, with: yesterday.to_s)
          click_on('Go')
        end

        it 'has the desired label' do
          expect(page).to have_css('label[for="created_at"]', text: 'Find by date requested:')
        end

        it 'returns requests matching create date only' do
          within('.table-striped/tbody') do
            expect(page).to have_css('tr', count: 2)
            expect(page).to have_css('tr/td/time', text: yesterday.to_s, count: 2)
          end
          fill_in(:created_at, with: today_s)
          click_on('Go')
          within('.table-striped/tbody') do
            expect(page).to have_css('tr', count: 3)
            expect(page).to have_css('tr/td/time', text: today_s, count: 3)
          end
        end

        it 'returns all request types' do
          within('.table-striped/tbody') do
            expect(page).to have_css('tr', text: 'MediatedPage')
            expect(page).to have_css('tr', text: 'Page')
          end
        end

        it 'is not paginated' do
          visit old_requests_path(per_page: 1)
          expect(page).to have_css('.pagination')
          fill_in(:created_at, with: yesterday.to_s)
          click_on('Go')
          expect(page).to have_no_css('.pagination')
        end

        it 'interacts nicely with request filters' do
          click_on 'Mediated pages'

          expect(page).to have_css('td', text: 'Mediated pages [x]')
          expect(page).to have_css('td a', text: 'Pages')
          within('.table-striped/tbody') do
            expect(page).to have_css('tr', count: 2)
            expect(page).to have_css('tr/td/time', text: yesterday.to_s)
            expect(page).to have_css('tr/td/time', text: today_s)
            expect(page).to have_css('tr', text: 'MediatedPage')
            expect(page).to have_no_css('tr', text: /^Page$/)
          end

          fill_in(:created_at, with: yesterday)
          click_on('Go')

          within('.table-striped/tbody') do
            expect(page).to have_css('tr', count: 2)
            expect(page).to have_css('tr/td/time', text: yesterday.to_s, count: 2)
          end
          expect(page).to have_no_css('td', text: 'Mediated pages [x]')
          expect(page).to have_css('td a', text: 'Mediated pages')
        end
      end
    end

    describe 'by an anonymous user' do
      before { stub_current_user(create(:anon_user)) }

      it 'redirects to the login page' do
        expect_any_instance_of(AdminController).to receive(:redirect_to).with(
          login_by_sunetid_path(referrer: old_requests_url)
        )
        visit old_requests_path
      end
    end
  end

  # see also features/mediation_table_spec
  describe 'show' do
    describe 'by a superadmin' do
      before do
        stub_current_user(create(:superadmin_user))
      end

      # rubocop:disable RSpec/LetSetup
      let!(:pages) { create_list(:mediated_page, 2) }
      let!(:other_pages) { create_list(:page_mp_mediated_page, 1) }
      # rubocop:enable RSpec/LetSetup

      it 'lists all the mediated pages for the given library' do
        visit admin_path('ART')

        expect(page).to have_css('h2', text: 'Art & Architecture Library (Bowes)')
        expect(page).to have_css('table tbody tr', count: 2)
      end

      describe 'pagination' do
        context 'on the "All pending" page' do
          before { visit admin_path('ART', per_page: 1) }

          it 'requests are not paginated' do
            expect(page).to have_no_css('.pagination')
          end
        end
      end

      it 'allows the user to toggle between done and pending mediated pages (and updates button class)' do
        build(:mediated_page, approval_status: :approved, needed_date: Time.zone.today - 2.days).save(validate: false)
        build(:mediated_page, approval_status: :approved, needed_date: Time.zone.today - 3.days).save(validate: false)
        build(:mediated_page, approval_status: :approved, needed_date: Time.zone.today - 1.day).save(validate: false)
        visit admin_path('ART')

        expect(page).to have_css('tbody tr', count: 2)
        expect(page).to have_css('a.btn-primary', text: 'All pending')

        expect(page).to have_css('a', text: 'All done')
        expect(page).to have_no_css('a.btn-primary', text: 'All done')
        click_on 'All done'

        expect(page).to have_css('h2', text: 'Art & Architecture Library (Bowes)')
        expect(page).to have_css('tbody tr', count: 3)
        expect(page).to have_css('a.btn-primary', text: 'All done')
        expect(page).to have_css('a', text: 'All pending')
        expect(page).to have_no_css('a.btn-primary', text: 'All pending')

        # requests are sorted properly (in descending needed_date order)
        expected_regex = /#{I18n.l(Time.zone.today - 1.day,
                                   format: :quick)}.*#{I18n.l(Time.zone.today - 2.days,
                                                              format: :quick)}.*#{I18n.l(Time.zone.today - 3.days, format: :quick)}/m
        expect(page).to have_content(expected_regex)

        click_on 'All pending'

        expect(page).to have_css('h2', text: 'Art & Architecture Library (Bowes)')
        expect(page).to have_css('tbody tr', count: 2)
      end
    end
  end

  describe 'by an anonymous user' do
    before { stub_current_user(create(:anon_user)) }

    it 'redirects to the login page' do
      expect_any_instance_of(AdminController).to receive(:redirect_to).with(
        login_by_sunetid_path(referrer: admin_url('ART'))
      )
      visit admin_path('ART')
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Viewing all requests' do
  before do
    allow_any_instance_of(FolioClient).to receive(:find_instance).and_return({ indexTitle: 'Item Title' })
    allow_any_instance_of(FolioClient).to receive(:resolve_to_instance_id).and_return('f1c52ab3-721e-5234-9a00-1023e034e2e8')
    allow_any_instance_of(FolioClient).to receive(:items_and_holdings).and_return(folio_holding_response)
  end

  let(:folio_holding_response) do
    { 'instanceId' => 'f1c52ab3-721e-5234-9a00-1023e034e2e8',
      'source' => 'MARC',
      'modeOfIssuance' => 'single unit',
      'natureOfContent' => [],
      'holdings' => [],
      'items' =>
       [{ 'id' => '584baef9-ea2f-5ff5-9947-bbc348aee4a4',
          'status' => 'Available',
          'barcode' => '3610512345678',
          'location' =>
          { 'effectiveLocation' => { 'code' => 'GRE-STACKS' },
            'permanentLocation' => { 'code' => 'GRE-STACKS' },
            'temporaryLocation' => {} },
          'callNumber' => { 'callNumber' => 'PR6123 .E475 W42 2009' },
          'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
          'materialType' => 'book',
          'permanentLoanType' => 'Can circulate',
          'suppressFromDiscovery' => false },
        { 'id' => '99466f50-2b8c-51d4-8890-373190b8f6c4',
          'status' => 'Available',
          'barcode' => '12345679',
          'location' =>
          { 'effectiveLocation' => { 'code' => 'GRE-STACKS' },
            'permanentLocation' => { 'code' => 'GRE-STACKS' },
            'temporaryLocation' => {} },
          'callNumber' => { 'callNumber' => 'PR6123 .E475 W42 2009' },
          'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
          'materialType' => 'book',
          'permanentLoanType' => 'Can circulate',
          'suppressFromDiscovery' => false },
        { 'id' => 'deec4ae9-545c-5d60-85b0-b1048b9dad05',
          'status' => 'Available',
          'barcode' => '36105028330483',
          'location' =>
          { 'effectiveLocation' => { 'code' => 'GRE-STACKS' },
            'permanentLocation' => { 'code' => 'GRE-STACKS' },
            'temporaryLocation' => {} },
          'callNumber' => { 'callNumber' => 'PR6123 .E475 W42 2009' },
          'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
          'materialType' => 'book',
          'permanentLoanType' => 'Can circulate',
          'suppressFromDiscovery' => false }] }
  end

  describe 'index' do
    describe 'by a superadmin user' do
      before do
        stub_current_user(create(:superadmin_user))
        create(:page, item_id: 2345, item_title: 'Fourth symphony. [Op. 51].',
                      user: User.create(sunetid: 'jstanford', email: 'jstanford@stanford.edu'))
        create(:page, item_id: 2346,
                      item_title: 'An American in Paris',
                      origin: 'SAL-NEWARK',
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
        visit admin_index_path

        expect(page).to have_css('td a[data-behavior="truncate"]', text: 'Fourth symphony. [Op. 51].')
        expect(page).to have_css('td a[href="mailto:jstanford@stanford.edu"]', text: /jstanford@stanford.edu/)

        expect(page).to have_css('td a[data-behavior="truncate"]', text: 'An American in Paris')
        expect(page).to have_css('td a[href="mailto:joe@xyz.com"]', text: /Joe \(joe@xyz.com\)/)

        expect(page).to have_css('td a[data-behavior="truncate"]', text: 'I am Mediated')
        expect(page).to have_css('td a[href="mailto:jane@example.com"]', text: /Jane \(jane@example.com\)/)

        expect(page).to have_selector('table.table-striped', count: 1)

        expect(page).to have_css('th.col-sm-1', text: 'Type')
        expect(page).to have_css('th.col-sm-1', text: 'Origin')
        expect(page).to have_css('th.col-sm-1', text: 'Destination')
        expect(page).to have_css('th.col-sm-5', text: 'Title')
        expect(page).to have_css('th.col-sm-2', text: 'Requester')
        expect(page).to have_css('th.col-sm-1', text: 'Requested on')
        expect(page).to have_css('th.col-sm-1', text: 'Status')
      end

      it 'allows filtering by request type' do
        visit admin_index_path

        expect(page).to have_css('td a', text: 'Mediated pages')
        expect(page).to have_css('td a', text: 'Pages')

        click_link 'Mediated pages'

        expect(page).to have_css('td', text: 'Mediated pages [x]')
        expect(page).to have_css('td a', text: 'Pages')

        expect(page).not_to have_css('td a[data-behavior="truncate"]', text: 'An American in Paris')
        expect(page).not_to have_css('td a[href="mailto:joe@xyz.com"]', text: /Joe \(joe@xyz.com\)/)

        expect(page).to have_css('td a[data-behavior="truncate"]', text: 'I am Mediated')
        expect(page).to have_css('td a[href="mailto:jane@example.com"]', text: /Jane \(jane@example.com\)/)

        click_link 'Pages'

        expect(page).to have_css('td a', text: 'Mediated pages')
        expect(page).to have_css('td', text: 'Pages [x]')

        expect(page).to have_css('td a[data-behavior="truncate"]', text: 'An American in Paris')
        expect(page).to have_css('td a[href="mailto:joe@xyz.com"]', text: /Joe \(joe@xyz.com\)/)

        expect(page).not_to have_css('td a[data-behavior="truncate"]', text: 'I am Mediated')
        expect(page).not_to have_css('td a[href="mailto:jane@example.com"]', text: /Jane \(jane@example.com\)/)

        click_link '[x]'

        expect(page).to have_css('td a', text: 'Mediated pages')
        expect(page).to have_css('td a', text: 'Pages')
      end

      context 'filter by create date' do
        yesterday = Time.zone.today - 1.day
        let(:today_s) { Time.zone.today.to_s }

        before do
          create(:page_mp_mediated_page, created_at: yesterday)
          create(:page, created_at: yesterday)
          visit admin_index_path
          fill_in(:created_at, with: yesterday.to_s)
          click_button('Go')
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
          click_button('Go')
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
          visit admin_index_path(per_page: 1)
          expect(page).to have_css('.pagination')
          fill_in(:created_at, with: yesterday.to_s)
          click_button('Go')
          expect(page).not_to have_css('.pagination')
        end

        it 'interacts nicely with request filters' do
          click_link 'Mediated pages'

          expect(page).to have_css('td', text: 'Mediated pages [x]')
          expect(page).to have_css('td a', text: 'Pages')
          within('.table-striped/tbody') do
            expect(page).to have_css('tr', count: 2)
            expect(page).to have_css('tr/td/time', text: yesterday.to_s)
            expect(page).to have_css('tr/td/time', text: today_s)
            expect(page).to have_css('tr', text: 'MediatedPage')
            expect(page).not_to have_css('tr', text: /^Page$/)
          end

          fill_in(:created_at, with: yesterday)
          click_button('Go')

          within('.table-striped/tbody') do
            expect(page).to have_css('tr', count: 2)
            expect(page).to have_css('tr/td/time', text: yesterday.to_s, count: 2)
          end
          expect(page).not_to have_css('td', text: 'Mediated pages [x]')
          expect(page).to have_css('td a', text: 'Mediated pages')
        end
      end
    end

    describe 'by an anonymous user' do
      before { stub_current_user(create(:anon_user)) }

      it 'redirects to the login page' do
        expect_any_instance_of(AdminController).to receive(:redirect_to).with(
          login_path(referrer: admin_index_url)
        )
        visit admin_index_path
      end
    end
  end

  # see also features/mediation_table_spec
  describe 'show' do
    describe 'by a superadmin' do
      before do
        stub_current_user(create(:superadmin_user))
        create(:mediated_page)
        create(:mediated_page)
        create(:page_mp_mediated_page)
      end

      it 'lists all the mediated pages for the given library' do
        visit admin_path('ART')

        expect(page).to have_css('h2', text: 'Art & Architecture Library (Bowes)')
        expect(page).to have_css('table tbody tr', count: 2)
      end

      describe 'pagination' do
        context 'on the "All pending" page' do
          before { visit admin_path('ART', per_page: 1) }

          it 'requests are not paginated' do
            expect(page).not_to have_css('.pagination')
          end
        end

        context 'on the "All done" page' do
          before do
            MediatedPage.all.map(&:approved!)
            visit admin_path('ART', done: 'true', per_page: 1)
          end

          it 'requests are paginated', js: true do
            expect(page).to have_css('.pagination')

            click_on 'Next ›'

            expect(page).to have_selector('.pagination .disabled', text: 'Next ›')
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
        expect(page).not_to have_css('a.btn-primary', text: 'All done')
        click_link 'All done'

        expect(page).to have_css('h2', text: 'Art & Architecture Library (Bowes)')
        expect(page).to have_css('tbody tr', count: 3)
        expect(page).to have_css('a.btn-primary', text: 'All done')
        expect(page).to have_css('a', text: 'All pending')
        expect(page).not_to have_css('a.btn-primary', text: 'All pending')

        # requests are sorted properly (in descending needed_date order)
        expected_regex = /#{Time.zone.today - 1.day}.*#{Time.zone.today - 2.days}.*#{Time.zone.today - 3.days}/m
        expect(page).to have_content(expected_regex)

        click_link 'All pending'

        expect(page).to have_css('h2', text: 'Art & Architecture Library (Bowes)')
        expect(page).to have_css('tbody tr', count: 2)
      end
    end
  end

  describe 'by an anonymous user' do
    before { stub_current_user(create(:anon_user)) }

    it 'redirects to the login page' do
      expect_any_instance_of(AdminController).to receive(:redirect_to).with(
        login_path(referrer: admin_url('ART'))
      )
      visit admin_path('ART')
    end
  end
end

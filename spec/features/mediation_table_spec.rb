# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Mediation table', :js do
  let(:top_level_columns) { 7 }
  let(:short_comment) { 'not a long comment' }

  context 'Library Mediation' do
    before do
      stub_bib_data_json(build(:searchable_holdings))
      stub_current_user(create(:superadmin_user))
      stub_symphony_response(ils_response)

      # create some pending requests
      create(
        :mediated_patron_request_with_holdings,
        barcodes: %w(12345678 23456789),
        created_at: 1.day.ago,
        needed_date: 3.days.from_now
      )
      create(
        :mediated_patron_request_with_holdings,
        patron: build(:library_id_patron, first_name: 'Joe', last_name: 'Doe', email: 'joedoe@example.com'),
        barcodes: %w(34567890 45678901),
        needed_date: 2.days.from_now
      )
      create(
        :mediated_patron_request_with_holdings,
        patron: build(:library_id_patron, first_name: 'Jim', last_name: 'Doe', email: 'jimdoe@example.com'),
        barcodes: %w(34567890),
        created_at: 1.day.from_now,
        needed_date: Time.zone.now
      )
      create(
        :mediated_patron_request,
        needed_date: Time.zone.now
      )

      # create some completed requests (don't validate, since validation disallows needed dates which fall in the past)
      build(
        :mediated_patron_request_with_holdings,
        request_type: 'mediated/approved',
        patron: build(:library_id_patron, first_name: 'Bob', last_name: 'Doe', email: 'bobdoe@example.com'),
        barcodes: %w(12345678 23456789),
        created_at: 7.days.ago,
        needed_date: 2.days.ago
      ).save(validate: false)
      build(
        :mediated_patron_request_with_holdings,
        request_type: 'mediated/approved',
        patron: build(:library_id_patron, first_name: 'Alice', last_name: 'Doe', email: 'alicedoe@example.com'),
        barcodes: %w(12345678 23456789),
        created_at: 5.days.ago,
        needed_date: 3.days.ago
      ).save(validate: false)
      build(
        :mediated_patron_request_with_holdings,
        request_type: 'mediated/done',
        patron: build(:library_id_patron, first_name: 'Mal', last_name: 'Doe', email: 'maldoe@example.com'),
        barcodes: %w(34567890 45678901),
        created_at: 3.days.ago,
        needed_date: nil
      ).save(validate: false)
      build(
        :mediated_patron_request_with_holdings,
        request_type: 'mediated/approved',
        patron: build(:library_id_patron, first_name: 'Eve', last_name: 'Doe', email: 'evedoe@example.com'),
        barcodes: %w(34567890),
        created_at: 2.days.ago,
        needed_date: nil
      ).save(validate: false)

      visit admin_path('ART')
    end

    describe 'current location' do
      let(:ils_response) { build(:symphony_page_with_multiple_items) }

      before do
        stub_bib_data_json(build(:searchable_holdings))
        visit(admin_path('ART'))
      end

      it 'is fetched from Symphony' do
        within(all('[data-mediate-request]').first) do
          click_on 'Toggle'
        end

        within('tbody td table') do
          expect(page).to have_css('td', text: 'ART-NEWBOOK')
        end
      end
    end

    context 'when the symphony response is successful' do
      let(:ils_response) { build(:symphony_page_with_multiple_items) }

      before do
        allow(SubmitFolioPatronRequestJob).to receive(:perform_now).and_return({ 'status' => 'ok' })
      end

      it 'has toggleable rows that display holdings' do
        expect(page).to have_css('[data-mediate-request]', count: 4)
        expect(page).to have_css('tbody tr', count: 4)
        within(all('[data-mediate-request]').last) do
          expect(page).to have_css('td', count: top_level_columns)
          click_on 'Toggle'
        end
        expect(page).to have_css("tbody td[colspan='#{top_level_columns}'] table")
        within("tbody td[colspan='#{top_level_columns}'] table") do
          expect(page).to have_css('td .btn', text: 'Approve', count: 2)
          expect(page).to have_css('td', text: 'ART-LOCKED-LARGE', count: 2)
          expect(page).to have_css('td', text: 'ABC 123')
          expect(page).to have_css('td', text: 'ABC 456')
        end
      end

      it 'has holdings that can be approved' do
        within(all('[data-mediate-request]').last) do
          click_on 'Toggle'
        end

        within('tbody td table tbody') do
          expect(page).to have_no_css('tr.approved')
          within(first('tr')) do
            expect(page).to have_css('td .btn', text: 'Approve')
            expect(page).to have_no_css('td', text: 'Added to pick list', visible: :visible)
            expect(page).to have_no_content('super-admin')
            click_on('Approve')
          end
          expect(page).to have_css('tr.approved')
          expect(page).to have_css('td .btn', text: 'Approved')

          within(first('tr')) do
            expect(page).to have_css('td', text: 'Added to pick list', visible: :visible)
            expect(page).to have_css('td', text: /super-admin - \d{4}-\d{2}-\d{2}/)
          end
        end
      end

      it 'indicates when all items in a request have been approved' do
        within(all('[data-mediate-request]').last) do
          expect(page).to have_no_css('[data-behavior="all-approved-note"]', text: 'Done')
          click_on 'Toggle'
        end

        within('tbody td table tbody') do
          within(all('tr').first) do
            click_on('Approve')
          end
        end

        expect(page).to have_content 'Approved'

        within('tbody td table tbody') do
          within(all('tr').last) do
            click_on('Approve')
          end
        end

        within(all('[data-mediate-request]').last) do
          expect(page).to have_css('[data-behavior="all-approved-note"]', text: 'Done')
        end
      end

      it 'has the expected default sort order for pending requests (needed on ascending, created on descending)' do
        within '.mediation-table tbody' do
          expect(page).to have_content(/Jim Doe.*Joe Doe.*Test User/m)
        end
      end

      it 'has the expected default sort order for completed requests (needed on descending, created on descending)' do
        visit admin_path('ART', done: 'true')
        within '.mediation-table tbody' do
          expect(page).to have_content(/Bob Doe.*Alice Doe.*Eve Doe.*Mal Doe/m)
        end
      end
    end
  end

  describe 'Filtering buttons' do
    before do
      stub_current_user(create(:superadmin_user))
    end

    describe 'for needed on dates' do
      before do
        create(:page_mp_mediated_patron_request, needed_date: Time.zone.today + 2.days)
        create(:mediated_patron_request_with_holdings, needed_date: Time.zone.today + 2.days)
        create(:mediated_patron_request_with_holdings, needed_date: Time.zone.today + 2.days)
        create(:mediated_patron_request_with_holdings, needed_date: Time.zone.today + 4.days)
        create(:mediated_patron_request_with_holdings, needed_date: Time.zone.today + 6.days)
        create(:mediated_patron_request_with_holdings, needed_date: Time.zone.today + 8.days)
        visit admin_path('ART')
      end

      it 'presents links for the next 3 days that have requests' do
        expect(page).to have_css('a.btn', text: I18n.l(Time.zone.today + 2.days, format: :quick))
        expect(page).to have_css('a.btn', text: I18n.l(Time.zone.today + 4.days, format: :quick))
        expect(page).to have_css('a.btn', text: I18n.l(Time.zone.today + 6.days, format: :quick))
        expect(page).to have_no_css('a.btn', text: I18n.l(Time.zone.today + 8.days, format: :quick))
      end

      it 'retains the origin filter' do
        find('a.btn', text: I18n.l(Time.zone.today + 2.days, format: :quick)).click
        expect(page).to have_css('tr[data-mediate-request]', count: 2) # would be 3 if the PAGE-MP request was included
      end

      it 'filters by the selected date' do
        find('a.btn', text: I18n.l(Time.zone.today + 2.days, format: :quick)).click
        expect(page).to have_css('a.btn-primary', text: I18n.l(Time.zone.today + 2.days, format: :quick))
        expect(page).to have_css('tr[data-mediate-request]', count: 2)

        find('a.btn', text: I18n.l(Time.zone.today + 4.days, format: :quick)).click
        expect(page).to have_css('a.btn-primary', text: I18n.l(Time.zone.today + 4.days, format: :quick))
        expect(page).to have_css('tr[data-mediate-request]', count: 1)
      end

      it 'returns unpaginated results' do
        visit admin_path('ART', per_page: 1)
        find('a.btn', text: I18n.l(Time.zone.today + 2.days, format: :quick)).click
        expect(page).to have_no_css('.pagination')
      end
    end
  end

  describe 'Date picker' do
    before { stub_current_user(create(:superadmin_user)) }

    describe 'for requested on dates' do
      let(:older) { Time.zone.today - 3.days }
      let(:today_s) { Time.zone.today.to_s }
      let(:yesterday) { Time.zone.today - 1.day }
      let(:future) { Time.zone.today + 2.days }
      let(:future_s) { I18n.l(future, format: :quick) }

      before do
        create(:mediated_patron_request_with_holdings, created_at: older)
        create(:mediated_patron_request_with_holdings, created_at: older)
        create(:mediated_patron_request_with_holdings, created_at: yesterday)
        create(:mediated_patron_request_with_holdings, created_at: yesterday)
        create(:page_mp_mediated_patron_request, created_at: yesterday)
        create(:mediated_patron_request_with_holdings, created_at: Time.zone.today)
        create(:mediated_patron_request_with_holdings, needed_date: future)
        visit admin_path('ART')
      end

      it 'retains the origin filter' do
        fill_in 'created_at', with: yesterday
        click_on('Go')
        expect(page).to have_css('tr[data-mediate-request]', count: 2) # would be 3 if the PAGE-MP request was included
      end

      it 'returns unpaginated results' do
        visit admin_path('ART', per_page: 1)
        fill_in 'created_at', with: yesterday
        click_on('Go')
        expect(page).to have_no_css('.pagination')
      end

      it 'returns requests matching create date only' do
        expect(page).to have_css('tr[data-mediate-request] td.created_at', text: older.to_s, count: 2)
        expect(page).to have_css('tr[data-mediate-request] td.created_at', text: yesterday.to_s, count: 2)
        expect(page).to have_css('tr[data-mediate-request] td.created_at', text: today_s, count: 2)

        fill_in 'created_at', with: yesterday
        click_on('Go')

        expect(page).to have_css('tr[data-mediate-request] td.created_at', text: yesterday.to_s, count: 2)
        expect(page).to have_no_css('tr[data-mediate-request] td.created_at', text: older.to_s)
        expect(page).to have_no_css('tr[data-mediate-request] td.created_at', text: today_s)
      end

      it 'includes both pending and done requests' do
        stub_bib_data_json(build(:page_mp_holdings))
        cdate = Time.zone.today - 8.days
        create(:page_mp_mediated_patron_request, created_at: cdate, barcodes: ['12345678'])
        create(:page_mp_mediated_patron_request, request_type: 'mediated/approved', created_at: cdate, barcodes: ['12345678'])
        visit admin_path('SAL3-PAGE-MP')
        fill_in 'created_at', with: cdate
        click_on('Go')
        # there are no mixed approvals
        expect(page).to have_no_css('td span[data-behavior="mixed-approved-note"]')
        # there is one each all-approved
        expect(page).to have_css('td span[data-behavior="all-approved-note"]')
      end

      it 'interacts appropriately with other date filters' do
        today_button_text = I18n.l(Time.zone.today, format: :quick)

        # All pending is primary, have right requests
        expect(page).to have_css('a.btn-primary', text: 'All pending')
        expect(page).to have_css('input[value="Go"]')

        fill_in 'created_at', with: yesterday
        click_on('Go')
        # correct dates, correct date filter
        expect(page).to have_css('tr[data-mediate-request] td.created_at', text: yesterday.to_s, count: 2)
        expect(page).to have_css('tr[data-mediate-request] td.needed_date', text: today_button_text, count: 2)
        expect(page).to have_no_css('a.btn-primary')
        expect(page).to have_css('input[value="Go"]')

        find('a.btn', text: future_s).click
        # correct dates, correct date filter
        expect(page).to have_css('tr[data-mediate-request] td.created_at', text: today_s)
        expect(page).to have_css('tr[data-mediate-request] td.needed_date', text: future_s)
        expect(page).to have_css('a.btn-primary', text: future_s)
        expect(page).to have_css('input[value="Go"]')

        fill_in 'created_at', with: Time.zone.today
        click_on('Go')
        expect(page).to have_css('tr[data-mediate-request] td.created_at', text: today_s, count: 2)
        expect(page).to have_css('tr[data-mediate-request] td.needed_date', text: today_button_text)
        expect(page).to have_css('tr[data-mediate-request] td.needed_date', text: future_s)
        expect(page).to have_no_css('a.btn-primary')
        expect(page).to have_css('input[value="Go"]')
      end
    end
  end

  context 'Location mediation' do
    let!(:request) do
      build(
        :page_mp_mediated_patron_request,
        patron: build(:library_id_patron, first_name: 'Joe', last_name: 'Doe', email: 'joedoe@example.com'),
        barcodes: %w(12345678 87654321)
      )
    end
    let(:request_status) do
      instance_double(ItemStatus, approved?: false, errored?: false)
    end

    before do
      stub_current_user(create(:page_mp_origin_admin_user))
      stub_bib_data_json(build(:page_mp_holdings))
      request.save(validate: false)

      visit admin_path('SAL3-PAGE-MP')
    end

    it 'has toggleable rows that display holdings' do
      expect(page).to have_css('[data-mediate-request]', count: 1)
      expect(page).to have_css('tbody tr', count: 1)
      within(first('[data-mediate-request]')) do
        expect(page).to have_css('td', count: top_level_columns)
        click_on 'Toggle'
      end

      expect(page).to have_css("tbody td[colspan='#{top_level_columns}'] table")
      within("tbody td[colspan='#{top_level_columns}'] table") do
        expect(page).to have_css('td .btn', text: 'Approve', count: 2)
        expect(page).to have_css('td', text: 'SAL3-PAGE-MP', count: 2)
        expect(page).to have_css('td', text: 'ABC 123')
        expect(page).to have_css('td', text: 'ABC 321')
      end
    end

    it 'has title and status links that open in a new window, with rel="noopener noreferrer"' do
      expect(page).to have_css('td.title a[target="_blank"][rel="noopener noreferrer"]', text: /Item Title/)
      expect(page).to have_css('td a[target="_blank"][rel="noopener noreferrer"]', text: 'Status')
    end

    it 'has a calendar widget for setting "Needed date"' do
      new_date = Time.zone.today.at_beginning_of_month.next_month

      within '.mediation-table tbody' do
        # find the table cell
        within 'td.needed_date' do
          # click the link to open the calendar widget
          click_on I18n.l(Time.zone.today, format: :quick)
          fill_in 'Needed on', with: new_date
          click_on 'ok'
        end
      end

      # confirm that the UI was updated to show the date selection made above,
      # and that the new selection has been saved to the object in the DB.
      expect(page).to have_link I18n.l(new_date, format: :quick)
      expect(request.reload.needed_date).to eq new_date
    end

    context 'for requests that do not have a needed date' do
      before do
        request.needed_date = nil
        request.save(validate: false)
      end

      it 'does not include the edit-in-place element' do
        visit admin_path('PAGE-MP')
        expect(page).to have_no_css('.needed_date a')
      end
    end
  end
end

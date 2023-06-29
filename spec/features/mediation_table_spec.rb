# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Mediation table', js: true do
  let(:top_level_columns) { 7 }
  let(:short_comment) { 'not a long comment' }

  context 'Library Mediation' do
    before do
      stub_current_user(create(:superadmin_user))
      stub_searchworks_api_json(build(:searchable_holdings))
      stub_symphony_response(ils_response)

      # create some pending requests
      create(
        :mediated_page_with_holdings,
        user: create(:non_sso_user),
        barcodes: %w(12345678 23456789),
        created_at: 1.day.ago,
        needed_date: 3.days.from_now
      )
      create(
        :mediated_page_with_holdings,
        user: create(:non_sso_user, name: 'Joe Doe ', email: 'joedoe@example.com'),
        barcodes: %w(34567890 45678901),
        needed_date: 2.days.from_now
      )
      create(
        :mediated_page_with_holdings,
        user: create(:non_sso_user, name: 'Jim Doe ', email: 'jimdoe@example.com'),
        barcodes: %w(34567890),
        created_at: 1.day.from_now,
        needed_date: Time.zone.now
      )
      create(
        :mediated_page,
        request_comment: short_comment,
        needed_date: Time.zone.now
      )

      # create some completed requests (don't validate, since validation disallows needed dates which fall in the past)
      build(
        :mediated_page_with_holdings,
        user: create(:non_sso_user, name: 'Bob Doe', email: 'bobdoe@example.com'),
        barcodes: %w(12345678 23456789),
        created_at: 7.days.ago,
        needed_date: 2.days.ago,
        approval_status: MediatedPage.approval_statuses['approved']
      ).save(validate: false)
      build(
        :mediated_page_with_holdings,
        user: create(:non_sso_user, name: 'Alice Doe ', email: 'alicedoe@example.com'),
        barcodes: %w(12345678 23456789),
        created_at: 5.days.ago,
        needed_date: 3.days.ago,
        approval_status: MediatedPage.approval_statuses['approved']
      ).save(validate: false)
      build(
        :mediated_page_with_holdings,
        user: create(:non_sso_user, name: 'Mal Doe ', email: 'maldoe@example.com'),
        barcodes: %w(34567890 45678901),
        created_at: 3.days.ago,
        needed_date: nil,
        approval_status: MediatedPage.approval_statuses['marked_as_done']
      ).save(validate: false)
      build(
        :mediated_page_with_holdings,
        user: create(:non_sso_user, name: 'Eve Doe ', email: 'evedoe@example.com'),
        barcodes: %w(34567890),
        created_at: 2.days.ago,
        needed_date: nil,
        approval_status: MediatedPage.approval_statuses['approved']
      ).save(validate: false)

      visit admin_path('ART')
    end

    context 'toggleable truncation of user request comments' do
      let(:ils_response) { build(:symphony_request_with_mixed_status) }

      it 'truncates long comments and shows a more link' do
        expect(page).to have_css('td.comment > div[data-behavior="trunk8toggle"]', count: 4)
        expect(page).to have_css('a.trunk8toggle-more', count: 3)
      end

      it 'can open and close long comments independently' do
        expect(page).to have_css('a.trunk8toggle-more', count: 3)
        expect(page).not_to have_css('a.trunk8toggle-less')

        page.first('a.trunk8toggle-more').click
        expect(page).to have_css('a.trunk8toggle-more', count: 2)
        expect(page).to have_css('a.trunk8toggle-less', count: 1)

        page.first('a.trunk8toggle-more').click
        expect(page).to have_css('a.trunk8toggle-more', count: 1)
        expect(page).to have_css('a.trunk8toggle-less', count: 2)

        page.first('a.trunk8toggle-less').click
        expect(page).to have_css('a.trunk8toggle-more', count: 2)
        expect(page).to have_css('a.trunk8toggle-less', count: 1)
      end

      it 'no truncation or "more" link for short comments' do
        within('td.comment > div[data-behavior="trunk8toggle"]', text: short_comment) do
          expect(page).not_to have_css('a.trunk8toggle-more')
        end
      end

      it 'column has size in header' do
        expect(page).to have_css('th.col-sm-3', text: 'Comment')
      end
    end

    describe 'current location' do
      let(:ils_response) { build(:symphony_page_with_multiple_items) }

      before do
        location_object = double(current_location: 'THE-CURRENT-LOCATION')
        expect(Symphony::CatalogInfo).to receive(:find).at_least(:once).and_return(location_object)
      end

      it 'is fetched from Symphony' do
        within(first('[data-mediate-request]')) do
          page.find('a.mediate-toggle').click
        end

        within('tbody td table') do
          expect(page).to have_css('td', text: 'THE-CURRENT-LOCATION')
        end
      end
    end

    describe 'successful symphony response' do
      let(:ils_response) { build(:symphony_page_with_multiple_items) }

      before do
        allow(Request.ils_job_class).to receive(:perform_now)
      end

      it 'has toggleable rows that display holdings' do
        expect(page).to have_css('[data-mediate-request]', count: 4)
        expect(page).to have_css('tbody tr', count: 4)
        within(all('[data-mediate-request]').last) do
          expect(page).to have_css('td', count: top_level_columns)
          page.find('a.mediate-toggle').click
        end
        expect(page).to have_css("tbody td[colspan='#{top_level_columns}'] table")
        within("tbody td[colspan='#{top_level_columns}'] table") do
          expect(page).to have_css('td button', text: 'Approve', count: 2)
          expect(page).to have_css('td', text: 'STACKS', count: 2)
          expect(page).to have_css('td', text: 'ABC 123')
          expect(page).to have_css('td', text: 'ABC 456')
        end
      end

      it 'has holdings that can be approved' do
        within(all('[data-mediate-request]').last) do
          page.find('a.mediate-toggle').click
        end

        within('tbody td table tbody') do
          expect(page).not_to have_css('tr.approved')
          within(first('tr')) do
            expect(page).to have_css('td button', text: 'Approve')
            expect(page).not_to have_css('td', text: 'Added to pick list', visible: :visible)
            expect(page).not_to have_content('super-admin')
            click_button('Approve')
          end
          expect(page).to have_css('tr.approved')
          expect(page).to have_css('td button', text: 'Approved')
          expect(page).to have_button('Approve', disabled: true)

          within(first('tr')) do
            expect(page).to have_css('td', text: 'Added to pick list', visible: :visible)
            expect(page).to have_css('td', text: /super-admin - \d{4}-\d{2}-\d{2}/)
          end
        end

        # and check that it is persisted
        visit admin_path('ART')

        within(all('[data-mediate-request]').last) do
          page.find('a.mediate-toggle').click
        end

        expect(page).to have_css('tr.approved')
        expect(page).to have_css('td button', text: 'Approved')
        expect(page).not_to have_css('.alert') # does not add request level alert
      end

      it 'indicates when all items in a request have been approved' do
        within(all('[data-mediate-request]').last) do
          expect(page).not_to have_css('[data-behavior="all-approved-note"]', text: 'Done')
          page.find('a.mediate-toggle').click
        end

        within('tbody td table tbody') do
          within(all('tr').first) do
            click_button('Approve')
            expect(page).to have_button('Approve', disabled: true)
          end

          within(all('tr').last) do
            click_button('Approve')
            expect(page).to have_button('Approve', disabled: true)
          end
        end

        within(all('[data-mediate-request]').last) do
          expect(page).to have_css('[data-behavior="all-approved-note"]', text: 'Done')
        end
      end

      it 'has the expected default sort order for pending requests (needed on ascending, created on descending)' do
        within '.mediation-table tbody' do
          expect(page).to have_content(/Jim Doe.*Joe Doe.*Jane Stanford/m)
        end
      end

      it 'has the expected default sort order for completed requests (needed on descending, created on descending)' do
        visit admin_path('ART', done: 'true')
        within '.mediation-table tbody' do
          expect(page).to have_content(/Bob Doe.*Alice Doe.*Eve Doe.*Mal Doe/m)
        end
      end

      it 'has sortable columns' do
        click_link 'Requested on'

        within '.mediation-table tbody' do
          expect(page).to have_content(/Jane Stanford.*Joe Doe.*Jim Doe/m)
        end

        click_link 'Requested on'

        within '.mediation-table tbody' do
          expect(page).to have_content(/Jim Doe.*Joe Doe.*Jane Stanford/m)
        end
      end
    end

    describe 'unsuccessful symphony responses' do
      let(:ils_response) { build(:symphony_request_with_mixed_status) }

      before do
        allow(Request.ils_job_class).to receive(:perform_now)
      end

      it 'has the persisted item level error message' do
        within(all('[data-mediate-request]').last) do
          page.find('a.mediate-toggle').click
        end

        within('tbody td table tbody') do
          last_tr = all('tr').last
          expect(last_tr['class']).to include 'errored'
          within(last_tr) do
            expect(page).to have_css('td', text: 'Item not found in catalog')
          end
        end
      end

      it 'returns the item level error text if it is not user-based' do
        within(all('[data-mediate-request]').last) do
          page.find('a.mediate-toggle').click
        end

        expect(page).not_to have_css('.alert.alert-danger', text: /There was a problem with this request/)

        within('tbody td table tbody') do
          within(all('tr').last) do
            click_button('Approve')

            wait_for_ajax
            approval_btn = page.find('button.approval-btn')
            expect(approval_btn).not_to be_disabled
          end
        end

        expect(page).to have_css('.alert.alert-danger', text: /There was a problem with this request/)
      end

      describe 'on item approval' do
        let(:ils_response) { build(:symphony_page_with_multiple_items) }

        it 'updates the item level error messages' do
          within(all('[data-mediate-request]').last) do
            page.find('a.mediate-toggle').click
          end

          within('tbody td table tbody') do
            within(all('tr').last) do
              expect(page).not_to have_css('td', text: 'Item not found in catalog')
              stub_symphony_response(build(:symphony_request_with_mixed_status))
              click_button('Approve')

              wait_for_ajax
              expect(page).to have_css('td', text: 'Item not found in catalog')
              approval_btn = page.find('button.approval-btn')
              expect(approval_btn).not_to be_disabled
            end
          end
        end
      end
    end
  end

  context 'contact email' do
    context 'for SSO users that do not have their email address previously set by LDAP' do
      before do
        stub_current_user(create(:superadmin_user))
        create(
          :mediated_page_with_holdings,
          user: create(:sso_user, sunetid: 'no-email-user', email: nil),
          barcodes: %w(12345678 23456789)
        )
      end

      it 'derives the email address from their sunetid' do
        visit admin_path('ART')

        within(first('[data-mediate-request]')) do
          expect(page).to have_link('no-email-user@stanford.edu', href: 'mailto:no-email-user@stanford.edu')
        end
      end
    end
  end

  describe 'Filtering buttons' do
    before { stub_current_user(create(:superadmin_user)) }

    describe 'for needed on dates' do
      before do
        create(:page_mp_mediated_page, needed_date: Time.zone.today + 2.days)
        create(:mediated_page_with_holdings, needed_date: Time.zone.today + 2.days)
        create(:mediated_page_with_holdings, needed_date: Time.zone.today + 2.days)
        create(:mediated_page_with_holdings, needed_date: Time.zone.today + 4.days)
        create(:mediated_page_with_holdings, needed_date: Time.zone.today + 6.days)
        create(:mediated_page_with_holdings, needed_date: Time.zone.today + 8.days)
        visit admin_path('ART')
      end

      it 'presents links for the next 3 days that have requests' do
        expect(page).to have_css('a.btn', text: I18n.l(Time.zone.today + 2.days, format: :quick))
        expect(page).to have_css('a.btn', text: I18n.l(Time.zone.today + 4.days, format: :quick))
        expect(page).to have_css('a.btn', text: I18n.l(Time.zone.today + 6.days, format: :quick))
        expect(page).not_to have_css('a.btn', text: I18n.l(Time.zone.today + 8.days, format: :quick))
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
        expect(page).not_to have_css('.pagination')
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
        create(:mediated_page_with_holdings, created_at: older)
        create(:mediated_page_with_holdings, created_at: older)
        create(:mediated_page_with_holdings, created_at: yesterday)
        create(:mediated_page_with_holdings, created_at: yesterday)
        create(:page_mp_mediated_page, created_at: yesterday)
        create(:mediated_page_with_holdings, created_at: Time.zone.today)
        create(:mediated_page_with_holdings, needed_date: future)
        visit admin_path('ART')
      end

      it 'retains the origin filter' do
        # Capybara thinks the date picker is invisible for some reason
        page.execute_script("$('input#created_at').prop('value', '#{yesterday}')")
        click_button('Go')
        expect(page).to have_css('tr[data-mediate-request]', count: 2) # would be 3 if the PAGE-MP request was included
      end

      it 'returns unpaginated results' do
        visit admin_path('ART', per_page: 1)
        page.execute_script("$('input#created_at').prop('value', '#{yesterday}')")
        click_button('Go')
        expect(page).not_to have_css('.pagination')
      end

      it 'returns requests matching create date only' do
        expect(page).to have_css('tr[data-mediate-request] td.created_at', text: older.to_s, count: 2)
        expect(page).to have_css('tr[data-mediate-request] td.created_at', text: yesterday.to_s, count: 2)
        expect(page).to have_css('tr[data-mediate-request] td.created_at', text: today_s, count: 2)

        page.execute_script("$('input#created_at').prop('value', '#{yesterday}')")
        click_button('Go')

        expect(page).to have_css('tr[data-mediate-request] td.created_at', text: yesterday.to_s, count: 2)
        expect(page).not_to have_css('tr[data-mediate-request] td.created_at', text: older.to_s)
        expect(page).not_to have_css('tr[data-mediate-request] td.created_at', text: today_s)
      end

      it 'includes both pending and done requests' do
        cdate = Time.zone.today - 8.days
        create(:page_mp_mediated_page, created_at: cdate)
        req = create(:page_mp_mediated_page, created_at: cdate)
        req.approved!
        visit admin_path('PAGE-MP')
        page.execute_script("$('input#created_at').prop('value', '#{cdate}')")
        click_button('Go')
        # there are no mixed approvals
        expect(page).not_to have_css('td span[data-behavior="mixed-approved-note"][style=""]', visible: :hidden)
        my_selector = 'td span[data-behavior="mixed-approved-note"][style="display:none;"]'
        expect(page).to have_css(my_selector, count: 2, visible: :hidden)
        # there is one each all-approved
        expect(page).to have_css('td span[data-behavior="all-approved-note"][style="display:none;"]', visible: :hidden)
        expect(page).to have_css('td span[data-behavior="all-approved-note"][style=""]', visible: :all)
      end

      it 'interacts appropriately with other date filters' do
        today_button_text = I18n.l(Time.zone.today, format: :quick)

        # All pending is primary, have right requests
        expect(page).to have_css('a.btn-primary', text: 'All pending')
        expect(page).to have_css('input.btn-primary[value="Go"]')

        page.execute_script("$('input#created_at').prop('value', '#{yesterday}')")
        click_button('Go')
        # correct dates, correct date filter
        expect(page).to have_css('tr[data-mediate-request] td.created_at', text: yesterday.to_s, count: 2)
        expect(page).to have_css('tr[data-mediate-request] td.needed_date', text: today_button_text, count: 2)
        expect(page).not_to have_css('a.btn-primary')
        expect(page).to have_css('input.btn-primary[value="Go"]')

        find('a.btn', text: future_s).click
        # correct dates, correct date filter
        expect(page).to have_css('tr[data-mediate-request] td.created_at', text: today_s)
        expect(page).to have_css('tr[data-mediate-request] td.needed_date', text: future_s)
        expect(page).to have_css('a.btn-primary', text: future_s)
        expect(page).to have_css('input.btn-primary[value="Go"]')

        page.execute_script("$('input#created_at').prop('value', '#{today_s}')")
        click_button('Go')
        expect(page).to have_css('tr[data-mediate-request] td.created_at', text: today_s, count: 2)
        expect(page).to have_css('tr[data-mediate-request] td.needed_date', text: today_button_text)
        expect(page).to have_css('tr[data-mediate-request] td.needed_date', text: future_s)
        expect(page).not_to have_css('a.btn-primary')
        expect(page).to have_css('input.btn-primary[value="Go"]')
      end
    end
  end

  context 'Location mediation' do
    let!(:request) do
      build(
        :page_mp_mediated_page,
        user: create(:non_sso_user, name: 'Joe Doe ', email: 'joedoe@example.com'),
        barcodes: %w(12345678 87654321)
      )
    end

    before do
      stub_current_user(create(:page_mp_origin_admin_user))
      stub_searchworks_api_json(build(:page_mp_holdings))
      request.save(validate: false)

      visit admin_path('PAGE-MP')
    end

    it 'has toggleable rows that display holdings' do
      expect(page).to have_css('[data-mediate-request]', count: 1)
      expect(page).to have_css('tbody tr', count: 1)
      within(first('[data-mediate-request]')) do
        expect(page).to have_css('td', count: top_level_columns)
        page.find('a.mediate-toggle').click
      end

      expect(page).to have_css("tbody td[colspan='#{top_level_columns}'] table")
      within("tbody td[colspan='#{top_level_columns}'] table") do
        expect(page).to have_css('td button', text: 'Approve', count: 2)
        expect(page).to have_css('td', text: 'STACKS', count: 2)
        expect(page).to have_css('td', text: 'ABC 123')
        expect(page).to have_css('td', text: 'ABC 321')
      end
    end

    it 'has title and status links that open in a new window, with rel="noopener noreferrer"' do
      expect(page).to have_css('td.title a[target="_blank"]', text: 'Title of MediatedPage 1234')
      expect(page).to have_css('td.title a[rel="noopener noreferrer"]', text: 'Title of MediatedPage 1234')
      expect(page).to have_css('td a[target="_blank"]', text: 'Status')
      expect(page).to have_css('td a[rel="noopener noreferrer"]', text: 'Status')
    end

    it 'has a calendar widget for setting "Needed date"' do
      within '.mediation-table tbody' do
        # confirm that the current value for the "needed date" is displayed correctly
        expect(page).to have_css('a.editable', text: I18n.l(Time.zone.today, format: :quick), visible: :visible)

        # find the table cell and click the link to open the calendar widget
        needed_date_table_cell = page.find('td.needed_date')
        needed_date_link = needed_date_table_cell.find('a')
        needed_date_link.click
        expect(page).to have_css('.editable-popup')

        within needed_date_table_cell do
          page.find('th.next').click # click over to the subsequent month
          expect(page).to have_css('td.day', visible: :visible) # make sure the calandar day elements have been rendered
          page.all('td.day').detect { |elt| elt.text == '1' }.click # click the calendar day for the first of the month
          page.find('button.editable-submit').click # submit the newly chosen date
        end
      end

      # use rails magic to get a Date object for the first of next month. then confirm that the UI was updated
      # to show the date selection made above, and that the new selection has been saved to the object in the DB.
      expected_needed_date = Time.zone.today.at_beginning_of_month.next_month
      expect(page).to have_css('a.editable', text: I18n.l(expected_needed_date, format: :quick), visible: :visible)
      expect(request.reload.needed_date).to eq expected_needed_date
    end

    context 'for requests that do not have a needed date' do
      before do
        request.needed_date = nil
        request.save(validate: false)
      end

      it 'does not include the edit-in-place element' do
        visit admin_path('PAGE-MP')
        expect(page).not_to have_css('a.editable')
      end
    end
  end
end

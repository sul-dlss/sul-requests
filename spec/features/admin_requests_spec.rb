# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Viewing all requests' do
  # see also features/mediation_table_spec
  describe 'show' do
    describe 'by a superadmin' do
      before do
        stub_current_user(create(:superadmin_user))
      end

      # rubocop:disable RSpec/LetSetup
      let!(:pages) { create_list(:mediated_patron_request, 2) }
      let!(:other_pages) { create_list(:page_mp_mediated_patron_request, 1) }
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
        build(:mediated_patron_request, request_type: 'mediated/approved', needed_date: Time.zone.today - 2.days).save(validate: false)
        build(:mediated_patron_request, request_type: 'mediated/approved', needed_date: Time.zone.today - 3.days).save(validate: false)
        build(:mediated_patron_request, request_type: 'mediated/approved', needed_date: Time.zone.today - 1.day).save(validate: false)
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

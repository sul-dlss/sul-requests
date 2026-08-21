# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Home Page' do
  before do
    allow(Illiad::Request).to receive(:where).and_return([])
  end

  describe 'layout' do
    before do
      visit root_path
    end

    it 'renders the page' do
      expect(page).to have_title('Requests : Stanford Libraries')
      expect(page).to have_css('.navbar-logo')
      expect(page).to have_link('My Account')
      expect(page).to have_link('Feedback')

      within('#su-footer') do
        expect(page).to have_css('.su-logo')
        expect(page).to have_link('Stanford Home')
        expect(page).to have_link('Maps & Directions')
        expect(page).to have_link('Search Stanford')
        expect(page).to have_link('Terms of Use')
        expect(page).to have_link('Emergency Info')
      end
    end
  end

  describe 'mediation section' do
    before do
      create(:mediated_patron_request)
      create(:page_mp_mediated_patron_request)
      stub_current_user(create(:superadmin_user))
      visit root_path
    end

    it 'has admin links for the library level mediation' do
      expect(page).to have_link('Art & Architecture Library (Bowes)', href: '/admin/ART')
      expect(page).to have_link('Earth Sciences Library (Branner)', href: '/admin/SAL3-PAGE-MP')
    end
  end

  context 'with the new layout', :js do
    before do
      allow(Settings.features).to receive(:requests_redesign).and_return(true)
      allow(Folio::Patron).to receive(:find_by).with(patron_key: user.patron_key).and_return(patron)
      allow(Aeon::User).to receive(:find_by).and_return(aeon_user)
      login_as(current_user)
    end

    let(:user) { create(:sso_user) }
    let(:current_user) { CurrentUser.new(username: user.sunetid, patron_key: user.patron_key, shibboleth: true, ldap_attributes: {}) }
    let(:aeon_user) { Aeon::User.new(username: user.email_address, auth_type: 'Default') }

    let(:patron) do
      build(:sponsor_patron)
    end

    it 'renders the cards' do
      visit root_path

      expect(page).to have_css('.card', count: 6)
      expect(page).to have_css('.card', text: 'Pickup requests')
      expect(page).to have_css('.card', text: '3 items currently loaned')
      expect(page).to have_css('.card', text: 'Digitization requests')
    end

    context 'with a FOLIO-only user' do
      let(:aeon_user) { Aeon::NullUser.new }

      it 'renders just the FOLIO cards' do
        visit root_path

        expect(page).to have_css('.card', count: 4)
        expect(page).to have_css('.card', text: 'Pickup requests')
        expect(page).to have_css('.card', text: 'Digitization requests')
        expect(page).to have_no_css('.card', text: 'Reading room appointments')
      end
    end

    context 'with an Aeon-only user' do
      let(:patron) { Folio::NullPatron.new }

      it 'renders just the Aeon cards' do
        visit root_path

        expect(page).to have_css('.card', count: 3)
        expect(page).to have_css('.card', text: 'Reading room appointments')
        expect(page).to have_css('.card', text: 'Digitization requests')
        expect(page).to have_no_css('.card', text: 'Pickup requests')
      end
    end

    context 'with an Aeon user with activities' do
      let(:patron) { Folio::NullPatron.new }

      before do
        allow(aeon_user).to receive(:activities).and_return(Aeon::ActivityFinders.new([Aeon::Activity.new]))
      end

      it 'renders an activities card' do
        visit root_path

        expect(page).to have_css('.card', text: 'Activities')
      end
    end

    context 'with an activity that has not started yet' do
      let(:patron) { Folio::NullPatron.new }

      before do
        activity = build(:aeon_activity, start_time: 2.days.from_now, stop_time: 4.days.from_now)
        allow(aeon_user).to receive(:activities).and_return(Aeon::ActivityFinders.new([activity]))
      end

      it 'shows the start date as the next one up' do
        visit root_path

        expect(page).to have_css('.card', text: '1 upcoming activity')
        expect(page).to have_css('.card', text: "Next up: #{2.days.from_now.strftime('%b %-d, %Y')}")
      end
    end

    context 'with an activity already in progress' do
      let(:patron) { Folio::NullPatron.new }

      before do
        activity = build(:aeon_activity, start_time: 1.day.ago, stop_time: 3.days.from_now)
        allow(aeon_user).to receive(:activities).and_return(Aeon::ActivityFinders.new([activity]))
      end

      it 'counts the activity as in progress' do
        visit root_path

        expect(page).to have_css('.card', text: '1 in progress')
      end

      it 'shows no next up date, because nothing is waiting to start' do
        visit root_path

        within('#aeon-activities') { expect(page).to have_no_text('Next up') }
      end

      it 'links to the current activities, not the past ones' do
        visit root_path

        within('#aeon-activities') do
          expect(page).to have_link('View details', href: aeon_activities_path)
        end
      end
    end

    context 'with one activity in progress and another still to start' do
      let(:patron) { Folio::NullPatron.new }

      before do
        activities = [
          build(:aeon_activity, id: 1, start_time: 1.day.ago, stop_time: 3.days.from_now),
          build(:aeon_activity, id: 2, start_time: 2.days.from_now, stop_time: 4.days.from_now)
        ]
        allow(aeon_user).to receive(:activities).and_return(Aeon::ActivityFinders.new(activities))
      end

      it 'counts each kind separately' do
        visit root_path

        expect(page).to have_css('.card', text: '1 in progress, 1 upcoming')
      end

      it 'shows the start date of the one still to start' do
        visit root_path

        expect(page).to have_css('.card', text: "Next up: #{2.days.from_now.strftime('%b %-d, %Y')}")
      end
    end
  end
end

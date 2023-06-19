# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Mark As Complete', js: true do
  let(:user) { create(:superadmin_user) }

  before do
    stub_searchworks_api_json(build(:searchable_holdings))
    stub_current_user(user)
  end

  describe 'marking an item as complete' do
    let!(:mediated_page) do
      create(
        :mediated_page_with_holdings,
        user: create(:non_sso_user, name: 'Jim Doe ', email: 'jimdoe@example.com'),
        barcodes: %w(34567890),
        created_at: 1.day.from_now
      )
    end

    before { visit admin_path('ART') }

    it 'saves state for the request object' do
      expect(mediated_page).not_to be_marked_as_done

      within(first('[data-mediate-request]')) do
        page.find('a.mediate-toggle').click
      end

      click_button 'Mark as done'

      expect(page).to have_css('[data-behavior="mixed-approved-note"]', visible: :visible) # to wait for ajax

      expect(MediatedPage.find(mediated_page.id)).to be_marked_as_done
    end

    it 'disables the button' do
      within(first('[data-mediate-request]')) do
        page.find('a.mediate-toggle').click
      end

      button = page.find('button', text: 'Mark as done')
      expect(button).not_to be_disabled

      click_button 'Mark as done'

      wait_for_ajax

      button = page.find('button', text: 'Mark as done')
      expect(button).to be_disabled
    end

    it 'shows the mixed-approval label on the request row' do
      expect(page).not_to have_css('[data-behavior="mixed-approved-note"]', visible: :visible)

      within(first('[data-mediate-request]')) do
        page.find('a.mediate-toggle').click
      end

      click_button 'Mark as done'

      expect(page).to have_css('[data-behavior="mixed-approved-note"]', visible: :visible)
    end
  end

  describe 'a request that has already been marked as complete' do
    before do
      create(
        :mediated_page_with_holdings,
        user: create(:non_sso_user, name: 'Jim Doe ', email: 'jimdoe@example.com'),
        barcodes: %w(34567890),
        approval_status: :marked_as_done,
        created_at: 1.day.from_now
      )
      visit admin_path('ART', done: 'true')
    end

    it 'has a disabled button' do
      within(first('[data-mediate-request]')) do
        page.find('a.mediate-toggle').click
      end

      button = page.find('button', text: 'Mark as done')
      expect(button).to be_disabled
    end

    it 'shows the mixed-approval label on the request row' do
      expect(page).to have_css('[data-behavior="mixed-approved-note"]', visible: :visible)
    end
  end
end

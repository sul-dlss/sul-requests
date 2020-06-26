# frozen_string_literal: true

require 'rails_helper'

describe 'Remote user confirmation' do
  context 'for webauth users' do
    it 'is not rendered' do
      stub_current_user(create(:webauth_user))
      visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')

      expect(page).not_to have_css('#remote-ip-check-overlay')
    end
  end

  context 'for non-webauth users' do
    before { stub_current_user(user) }

    context 'that are in the configured IP ranges' do
      let(:user) { create(:anon_user, ip_address: Settings.stanford_ips.singletons.first) }

      it 'is not rendered' do
        visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')

        expect(page).not_to have_css('#remote-ip-check-overlay')
      end
    end

    context 'that are not in the configured IP ranges' do
      let(:user) { create(:anon_user, ip_address: '123.45.6.78') }

      it 'is rendered' do
        visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')

        expect(page).to have_css('#remote-ip-check-overlay')
      end
    end
  end

  context 'for requests that should not get the confirmation screen at all' do
    it 'is not rendered for non-mediated pages' do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')

      expect(page).not_to have_css('#remote-ip-check-overlay')
    end

    # Hopkins isn't mediated now, and not getting remote IP checks
    pending 'is not rendered for HOPKINS mediated pages' do
      visit new_mediated_page_path(item_id: '1234', origin: 'HOPKINS', origin_location: 'STACKS')

      expect(page).not_to have_css('#remote-ip-check-overlay')
    end
  end

  describe 'confirmation buttons' do
    it 'hides the overlay when the "Yes" button is clicked', js: true do
      visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')

      expect(page).to have_css('#remote-ip-check-overlay', visible: :visible)

      within('#remote-ip-check-overlay') do
        click_button
      end

      expect(page).not_to have_css('#remote-ip-check-overlay', visible: :visible)
    end

    it 'includes a link styled like a button that send the user to the record in SearchWorks' do
      visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')

      expect(page).to have_link('Not right now', href: "#{Settings.searchworks_link}/1234")
    end
  end
end

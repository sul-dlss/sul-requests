# frozen_string_literal: true

require 'rails_helper'

describe 'Remote user confirmation' do
  context 'for webauth users' do
    it 'is not rendered' do
      stub_current_user(create(:webauth_user))
      visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')

      expect(page).not_to have_css('.non-stanford-user-overlay')
    end
  end

  context 'for non-webauth users' do
    before { stub_current_user(user) }

    context 'that are in the configured IP ranges' do
      let(:user) { create(:anon_user, ip_address: Settings.stanford_ips.singletons.first) }

      it 'is not rendered' do
        visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')

        expect(page).not_to have_css('.non-stanford-user-overlay')
      end
    end

    pending 'that are not in the configured IP ranges' do
      let(:user) { create(:anon_user, ip_address: '123.45.6.78') }

      it 'is rendered' do
        visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')

        expect(page).to have_css('.non-stanford-user-overlay')
      end
    end
  end

  context 'for requests that should not get the confirmation screen at all' do
    it 'is not rendered for non-mediated pages' do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')

      expect(page).not_to have_css('.non-stanford-user-overlay')
    end

    it 'is not rendered for HOPKINS mediated pages' do
      visit new_mediated_page_path(item_id: '1234', origin: 'HOPKINS', origin_location: 'STACKS')

      expect(page).not_to have_css('.non-stanford-user-overlay')
    end
  end

  pending 'confirmation buttons' do
    it 'hides the overlay when the "Yes" button is clicked', js: true do
      visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')

      expect(page).to have_css('.non-stanford-user-overlay', visible: true)

      within('.non-stanford-user-overlay') do
        click_button
      end

      expect(page).not_to have_css('.non-stanford-user-overlay', visible: true)
    end

    it 'includes a link styled like a button that send the user to the record in SearchWorks' do
      visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')

      expect(page).to have_link('Not right now', href: "#{Settings.searchworks_link}/1234")
    end
  end
end

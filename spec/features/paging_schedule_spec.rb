# frozen_string_literal: true

require 'rails_helper'

describe 'Paging Schedule' do
  before { stub_current_user(create(:superadmin_user)) }

  describe 'admin list' do
    it 'displays the currently configured paging schedule' do
      visit paging_schedule_index_path

      expect(page).to have_css('h1', text: 'Paging schedule')

      expect(page).to have_css('h2', text: 'SAL3')
      expect(page).to have_content('When paging to GREEN before')
    end
  end

  describe 'Select dropdown', js: true do
    before { stub_searchworks_api_json(build(:sal3_holdings)) }

    it 'displays the estimate for the currently selected value and updates it when a new destination is selected' do
      visit new_page_path(item_id: '1234', origin: 'SAL3', origin_location: 'STACKS')

      expect(page).to have_select('request_destination', selected: 'Green Library')

      expect(page).to have_css('[data-scheduler-text]', text: /, (before|after)/, visible: true)
      before_text = find('[data-scheduler-text]').text

      select 'Engineering Library (Terman)', from: 'request_destination'
      expect(find('[data-scheduler-text]')).not_to eq before_text
    end
  end

  describe 'Estimated delivery', js: true do
    before do
      stub_current_user(create(:webauth_user))
      stub_searchworks_api_json(build(:sal3_holdings))
    end

    it 'is persisted' do
      stub_symphony_response(build(:symphony_page_with_single_item))
      visit new_page_path(item_id: '1234', origin: 'SAL3', origin_location: 'STACKS')

      expect(page).to have_css('[data-scheduler-text]', text: /, (before|after)/, visible: true)
      schedule_text = find('[data-scheduler-text]').text

      within('#item-selector') do
        check('ABC 123')
      end

      first(:button, 'Send request').click

      expect(page).to have_css('dt', text: /Estimated delivery/i)
      expect(page).to have_css('dd', text: schedule_text)
    end
  end

  describe 'Single library destination', js: true do
    it 'displays an estimate for the single possible destination' do
      visit new_page_path(item_id: '1234', origin: 'SAL3', origin_location: 'PAGE-MA')

      expect(page).not_to have_select('request_destination')
      expect(page).to have_css('[data-scheduler-text]', text: /, (before|after)/, visible: true)
    end
  end

  describe 'form choice page', js: true do
    before { stub_searchworks_api_json(build(:sal3_holdings)) }

    it 'shows the estimated delivery for Green Library' do
      visit new_request_path(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS')

      within('#deliveryDescription') do
        expect(page).to have_css('[data-scheduler-text]', text: /, (before|after)/, visible: true)
      end
    end
  end

  describe 'scan form', js: true do
    before { stub_searchworks_api_json(build(:sal3_holdings)) }

    it 'shows the estimated delivery for the Scanning service' do
      visit new_scan_path(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS')

      expect(page).to have_css('[data-scheduler-text]', text: /, (before|after)/, visible: true)
    end
  end
end

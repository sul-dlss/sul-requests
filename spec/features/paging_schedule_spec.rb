# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Paging Schedule' do
  let(:all_items) do
    [
      double('item', callnumber: 'ABC 123', processing?: false, missing?: false, hold?: false, on_order?: false, hold_recallable?: false,
                     barcode: '123123124', checked_out?: false, status_class: 'active', status_text: 'Active', public_note: 'huh?',
                     type: 'STKS', effective_location: build(:location),
                     material_type: build(:book_material_type), loan_type: double(id: nil)),
      double('item', callnumber: 'ABC 321', processing?: false, missing?: false, hold?: false, on_order?: false, hold_recallable?: false,
                     barcode: '9928812', checked_out?: false, status_class: 'active', status_text: 'Active', public_note: 'huh?',
                     type: 'STKS', effective_location: build(:location),
                     material_type: build(:book_material_type), loan_type: double(id: nil))
    ]
  end

  before do
    allow(Settings.ils.bib_model.constantize).to receive(:fetch).and_return(double(:bib_data, title: 'Test title',
                                                                                              request_holdings: all_items))
    stub_current_user(create(:superadmin_user))
  end

  describe 'admin list' do
    it 'displays the currently configured paging schedule' do
      visit paging_schedule_index_path

      expect(page).to have_css('h1', text: 'Paging schedule')

      expect(page).to have_css('h2', text: 'SAL3')
      expect(page).to have_content('When paging to GREEN before')
    end
  end

  describe 'Select dropdown', js: true do
    before do
      pending('We are not showing the paging schedule for pages during the migration') if Settings.features.migration
    end

    it 'displays the estimate for the currently selected value and updates it when a new destination is selected' do
      visit new_page_path(item_id: '1234', origin: 'SAL3', origin_location: 'STACKS')

      expect(page).to have_select('request_destination', selected: 'Green Library')

      expect(page).to have_css('[data-scheduler-text]', text: /, (before|after)/, visible: :visible)
      before_text = find('[data-scheduler-text]').text

      select 'Engineering Library (Terman)', from: 'request_destination'
      expect(find('[data-scheduler-text]')).not_to eq before_text
    end
  end

  describe 'Estimated delivery', js: true do
    before do
      pending('We are not showing the paging schedule for pages during the migration') if Settings.features.migration

      stub_current_user(create(:sso_user))
      stub_symphony_response(build(:symphony_page_with_single_item))
    end

    it 'is persisted' do
      visit new_page_path(item_id: '1234', origin: 'SAL3', origin_location: 'STACKS')

      expect(page).to have_css('[data-scheduler-text]', text: /, (before|after)/, visible: :visible)
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
    let(:all_items) do
      [
        double('item', callnumber: 'ABC 123', processing?: false, missing?: false, hold?: false, on_order?: false, hold_recallable?: false,
                       barcode: '123123124', checked_out?: false, status_class: 'active', status_text: 'Active', public_note: 'huh?',
                       type: 'STKS', effective_location: Folio::Types.locations.find_by(code: 'SAL3-PAGE-EN'),
                       material_type: build(:book_material_type), loan_type: double(id: nil))
      ]
    end

    before do
      pending('We are not showing the paging schedule for pages during the migration') if Settings.features.migration
    end

    it 'displays an estimate for the single possible destination' do
      visit new_page_path(item_id: '1234', origin: 'SAL3', origin_location: 'PAGE-EN')

      expect(page).not_to have_select('request_destination')
      expect(page).to have_css('[data-scheduler-text]', text: /, (before|after)/, visible: :visible)
    end
  end

  describe 'form choice page', js: true do
    before do
      pending('We are not showing the paging schedule for pages during the migration') if Settings.features.migration

      stub_bib_data_json(build(:scannable_holdings))
    end

    it 'shows the estimated delivery for Green Library' do
      visit new_request_path(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS')

      within('#deliveryDescription') do
        expect(page).to have_css('[data-scheduler-text]', text: /, (before|after)/, visible: :visible)
      end
    end
  end

  describe 'scan form', js: true do
    before do
      stub_bib_data_json(build(:scannable_holdings))
    end

    it 'shows the estimated delivery for the Scanning service' do
      visit new_scan_path(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS')

      expect(page).to have_css('[data-scheduler-text]', text: /, (before|after)/, visible: :visible)
    end
  end
end

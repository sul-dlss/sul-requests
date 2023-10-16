# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Paging Schedule' do
  let(:all_items) do
    [
      double('item', callnumber: 'ABC 123', processing?: false, missing?: false, hold?: false, on_order?: false, hold_recallable?: false,
                     pageable?: true, mediateable?: false, barcode: '123123124', checked_out?: false, status_class: 'active',
                     status_text: 'Active', public_note: 'huh?', type: 'STKS', effective_location: build(:location), requestable?: true,
                     permanent_location: build(:location), material_type: build(:book_material_type), loan_type: double(id: nil)),
      double('item', callnumber: 'ABC 321', processing?: false, missing?: false, hold?: false, on_order?: false, hold_recallable?: false,
                     pageable?: true, mediateable?: false, barcode: '9928812', checked_out?: false, status_class: 'active',
                     status_text: 'Active', public_note: 'huh?', type: 'STKS', effective_location: build(:location), requestable?: true,
                     permanent_location: build(:location), material_type: build(:book_material_type), loan_type: double(id: nil))
    ]
  end

  let(:instance) { instance_double(Folio::Instance, title: 'Test title', request_holdings: all_items, items: []) }

  before do
    allow(Settings.ils.bib_model.constantize).to receive(:fetch).and_return(instance)
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

  describe 'Select dropdown', :js do
    before do
      pending('We are not showing the paging schedule for pages during the migration') if Settings.features.migration
    end

    it 'displays the estimate for the currently selected value and updates it when a new destination is selected' do
      visit new_page_path(item_id: '1234', origin: 'SAL3', origin_location: 'SAL3-STACKS')

      expect(page).to have_select('request_destination', selected: 'Green Library')

      expect(page).to have_css('[data-scheduler-text]', text: /, (before|after)/, visible: :visible)
      before_text = find('[data-scheduler-text]').text

      select 'Engineering Library (Terman)', from: 'request_destination'
      expect(find('[data-scheduler-text]')).not_to eq before_text
    end
  end

  describe 'Estimated delivery', :js do
    before do
      pending('We are not showing the paging schedule for pages during the migration') if Settings.features.migration

      stub_current_user(create(:sso_user))
      stub_symphony_response(build(:symphony_page_with_single_item))
    end

    it 'is persisted' do
      visit new_page_path(item_id: '1234', origin: 'SAL3', origin_location: 'SAL3-STACKS')

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

  describe 'Single library destination', :js do
    let(:all_items) do
      [
        double('item', callnumber: 'ABC 123', processing?: false, missing?: false, hold?: false, on_order?: false, hold_recallable?: false,
                       pageable?: true, mediateable?: false, barcode: '123123124', checked_out?: false, status_class: 'active',
                       status_text: 'Active', public_note: 'huh?', type: 'STKS', effective_location: build(:page_en_location),
                       requestable?: true, permanent_location: build(:page_en_location), material_type: build(:book_material_type),
                       loan_type: double(id: nil))
      ]
    end

    before do
      pending('We are not showing the paging schedule for pages during the migration') if Settings.features.migration
    end

    it 'displays an estimate for the single possible destination' do
      visit new_page_path(item_id: '1234', origin: 'SAL3', origin_location: 'SAL3-PAGE-EN')

      expect(page).not_to have_select('request_destination')
      expect(page).to have_css('[data-scheduler-text]', text: /, (before|after)/, visible: :visible)
    end
  end

  describe 'form choice page', :js do
    before do
      pending('We are not showing the paging schedule for pages during the migration') if Settings.features.migration

      stub_bib_data_json(build(:scannable_holdings))
    end

    it 'shows the estimated delivery for Green Library' do
      visit new_request_path(item_id: '12345', origin: 'SAL3', origin_location: 'SAL3-STACKS')

      within('#deliveryDescription') do
        expect(page).to have_css('[data-scheduler-text]', text: /, (before|after)/, visible: :visible)
      end
    end
  end

  describe 'scan form', :js do
    before do
      stub_bib_data_json(build(:scannable_holdings))
    end

    it 'shows the estimated delivery for the Scanning service' do
      visit new_scan_path(item_id: '12345', origin: 'SAL3', origin_location: 'SAL3-STACKS')

      expect(page).to have_css('[data-scheduler-text]', text: /, (before|after)/, visible: :visible)
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Public Notes', js: true do
  let(:user) { create(:sso_user) }
  let(:holdings_relationship) { double(:relationship, where: selected_items, all: all_items) }
  let(:selected_items) do
    [
      double(:item, barcode: '12345678', checked_out?: false, processing?: false, missing?: false, hold?: false,
                    on_order?: false, callnumber: 'ABC 123', status_class: 'available', status_text: 'Available'),
      double(:item, barcode: '23456789', checked_out?: false, processing?: false, missing?: false, hold?: false,
                    on_order?: false, callnumber: 'ABC 456', status_class: 'available', status_text: 'Available'),
      double(:item, barcode: '34567890', checked_out?: false, processing?: false, missing?: false, hold?: false,
                    on_order?: false, callnumber: 'ABC 012', status_class: 'available', status_text: 'Available'),
      double(:item, barcode: '45678901', checked_out?: false, processing?: false, missing?: false, hold?: false,
                    on_order?: false, callnumber: 'ABC 345', status_class: 'available', status_text: 'Available')
    ]
  end
  let(:all_items) do
    [
      double(:item, barcode: '12345678', checked_out?: false, processing?: false, missing?: false, hold?: false,
                    on_order?: false, callnumber: 'ABC 123', status_class: 'available', status_text: 'Available',
                    public_note: nil),
      double(:item, barcode: '23456789', checked_out?: false, processing?: false, missing?: false, hold?: false,
                    on_order?: false, callnumber: 'ABC 456', status_class: 'available', status_text: 'Available',
                    public_note: 'note for 23456789'),
      double(:item, barcode: '34567890', checked_out?: false, processing?: false, missing?: false, hold?: false,
                    on_order?: false, callnumber: 'ABC 012', status_class: 'available', status_text: 'Available',
                    public_note: nil),
      double(:item, barcode: '45678901', checked_out?: false, processing?: false, missing?: false, hold?: false,
                    on_order?: false, callnumber: 'ABC 345', status_class: 'available', status_text: 'Available',
                    public_note: 'note for 45678901')
    ]
  end

  before do
    allow_any_instance_of(PagingSchedule::Scheduler).to receive(:valid?).with(anything).and_return(true)
    allow(Settings.ils.bib_model.constantize).to receive(:new).and_return(double(:bib_data, title: 'Test title'))
    allow(HoldingsRelationshipBuilder).to receive(:build).and_return(holdings_relationship)
  end

  describe 'public_notes' do
    before do
      stub_current_user(user)
      stub_searchworks_api_json(build(:searchable_holdings))
    end

    it 'persists to the database as hash of barcode=>note pairs' do
      visit new_mediated_page_path(item_id: '1234', origin: 'ART', origin_location: 'ARTLCKL')

      fill_in_required_fields

      within('#item-selector') do
        check('ABC 123')
        check('ABC 456')
        check('ABC 012')
        check('ABC 345')
      end

      first(:button, 'Send request').click

      expect_to_be_on_success_page

      expect(MediatedPage.last.public_notes).to eq('45678901' => 'note for 45678901', '23456789' => 'note for 23456789')
    end
  end
end

def fill_in_required_fields
  wait_for_ajax
  min_date = find_by_id('request_needed_date')['min']
  page.execute_script("$('#request_needed_date').prop('value', '#{min_date}')")
end

# frozen_string_literal: true

require 'rails_helper'

describe 'Public Notes', js: true do
  let(:user) { create(:webauth_user) }

  before do
    allow_any_instance_of(PagingSchedule::Scheduler).to receive(:valid?).with(anything).and_return(true)
  end

  describe 'public_notes' do
    before do
      stub_current_user(user)
      stub_searchworks_api_json(build(:searchable_holdings))
    end

    it 'persists to the database as hash of barcode=>note pairs' do
      visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')

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
  # TODO: COVID-19 don't need to fill in date field
  # wait_for_ajax
  #
  # min_date = find('#request_needed_date', visible: :hidden)['min']
  # page.execute_script("$('#request_needed_date').prop('value', '#{min_date}')")
end

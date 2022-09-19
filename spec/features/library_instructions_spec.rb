# frozen_string_literal: true

require 'rails_helper'

describe 'Library Instructions' do
  before { stub_searchworks_api_json(build(:library_instructions_holdings)) }

  it 'returns the library instructions from the API' do
    visit new_request_path(item_id: '12345', origin: 'ART', origin_location: 'ARTLCKL')

    within('p.needed-date-info-block') do
      expect(page).to have_content('This is the library instruction')
    end
  end
end

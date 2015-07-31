require 'rails_helper'

describe 'Library Instructions' do
  before { stub_searchworks_api_json(build(:library_instructions_holdings)) }
  it 'returns the library instructions from the API' do
    visit new_request_path(item_id: '12345', origin: 'SPEC-COLL', origin_location: 'STACKS')

    within('.alert.alert-info') do
      expect(page).to have_css('h4', text: 'Instruction Heading')
      expect(page).to have_content('This is the library instruction')
    end
  end
end

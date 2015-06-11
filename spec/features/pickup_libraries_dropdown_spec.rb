require 'rails_helper'

describe 'Pickup Libraries Dropdown' do
  describe 'for multiple libraries' do
    it 'should have a select dropdown to choose the library to deliver to' do
      visit new_request_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')

      expect(page).to have_select('Deliver to')

      expect(page).to have_css('#request_destination option', count: 15)
    end

    it 'should simply display the text of the destination library if there is only one possible' do
      visit new_request_path(item_id: '1234', origin: 'ARS', origin_location: 'STACKS')

      expect(page).to_not have_css('select')

      expect(page).to have_css('.form-group .control-label', text: 'Must be used in')
      expect(page).to have_css('.form-group .input-like-text', text: 'Archive of Recorded Sound')
    end
  end
end

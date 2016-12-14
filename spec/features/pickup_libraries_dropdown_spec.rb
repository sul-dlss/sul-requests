require 'rails_helper'

describe 'Pickup Libraries Dropdown' do
  describe 'for multiple libraries' do
    it 'should have a select dropdown to choose the library to deliver to' do
      visit new_request_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')

      expect(page).to have_select('Deliver to')

      expect(page).to have_css('#request_destination option', count: 12)
    end

    it 'should simply display the text of the destination library if there is only one possible' do
      visit new_request_path(item_id: '1234', origin: 'ARS', origin_location: 'STACKS')

      expect(page).to_not have_css('select')

      expect(page).to have_css('.form-group .control-label', text: 'Will be delivered to')
      expect(page).to have_css('.form-group .input-like-text', text: 'Archive of Recorded Sound')
    end
  end

  describe 'libraries that should include themself in the pickup list' do
    context 'a standard library' do
      it 'does not include the configured library in the drop down' do
        visit new_request_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')

        expect(page).to have_css('#request_destination option', count: 12)
        expect(page).not_to have_css('option', text: 'Media Microtext')
      end
    end

    context 'libraries that are configured' do
      it 'appear in the drop down' do
        visit new_request_path(item_id: '1234', origin: 'MEDIA-MTXT', origin_location: 'MM-STACKS')

        expect(page).to have_css('#request_destination option', count: 13)
        expect(page).to have_css('option', text: 'Media Microtext')
      end
    end
  end
end

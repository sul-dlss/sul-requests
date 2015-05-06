require 'rails_helper'

describe 'Item Selector' do
  describe 'for single items' do
    before { stub_searchworks_api_json(build(:single_holding)) }
    it 'is not displayed' do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')
      expect(page).to have_css('p', text: 'ABC 123')
      expect(page).to_not have_css('#item-selector')
    end
  end
  describe 'for multiple items', js: true do
    before do
      stub_searchworks_api_json(build(:multiple_holdings))
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')
    end
    it 'displayes the selected item count' do
      expect(page).to have_css('p[data-items-counter]', text: '0 items selected')

      within('#item-selector') do
        check('ABC 123')
      end

      expect(page).to have_css('p[data-items-counter]', text: '1 items selected')

      within('#item-selector') do
        check('ABC 321')
      end

      expect(page).to have_css('p[data-items-counter]', text: '2 items selected')

      within('#item-selector') do
        uncheck('ABC 123')
      end

      expect(page).to have_css('p[data-items-counter]', text: '1 items selected')
    end
  end
end

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
      stub_searchworks_api_json(holdings)
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')
    end
    describe 'where there are not enough to be searchable' do
      let(:holdings) { build(:multiple_holdings) }
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

    describe 'when there are enough to be searchable' do
      let(:holdings) { build(:searchable_holdings) }
      it 'dows not allow more than 5 to be selected' do
        within('#item-selector') do
          check('ABC 123')
          check('ABC 456')
          check('ABC 789')
          check('ABC 012')
          check('ABC 345')

          check('ABC 678')
          expect(field_labeled('ABC 678')).to_not be_checked
        end
      end
      it 'limits items using the search box' do
        within('#item-selector') do
          expect(page).to have_css('.input-group', count: 10)
        end

        within('#selected-items-filter') do
          fill_in 'Search item list', with: 'ABC 901'
        end

        within('#item-selector') do
          expect(page).to have_css('.input-group', count: 1)
        end
      end

      it 'prevents users from selecting more than 5 items after search' do
        within('#item-selector') do
          check('ABC 123')
          check('ABC 456')
          check('ABC 789')
          check('ABC 012')
          check('ABC 345')
        end

        within('#selected-items-filter') do
          fill_in 'Search item list', with: 'ABC 901'
        end

        within('#item-selector') do
          check('ABC 901')
          expect(field_labeled('ABC 901')).to_not be_checked
        end
      end
    end
  end
end

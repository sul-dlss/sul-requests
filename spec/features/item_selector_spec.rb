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
      visit request_path
    end
    describe 'where there are not enough to be searchable' do
      let(:request_path) { new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS') }
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

    describe 'item limits' do
      describe 'for scans' do
        let(:request_path) { new_scan_path(item_id: '1234', origin: 'SAL3', origin_location: 'STACKS') }
        let(:holdings) { build(:sal3_holdings) }
        it 'only allows one to be selected' do
          within('#item-selector') do
            check('ABC 123')
            check('ABC 321')
            expect(field_labeled('ABC 321')).to_not be_checked
          end
          expect(page).to have_content('1 items selected')
        end
      end

      describe 'for pages' do
        let(:request_path) { new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS') }
        let(:holdings) { build(:many_holdings) }
        it 'does not limit selection' do
          within('#item-selector') do
            check('ABC 123')
            check('ABC 456')
            check('ABC 789')
            check('ABC 012')
            check('ABC 345')

            check('ABC 678')
            expect(field_labeled('ABC 678')).to be_checked
          end
          expect(page).to have_content('6 items selected')
        end
      end

      describe 'for mediated pages' do
        let(:request_path) { new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS') }
        let(:holdings) { build(:searchable_holdings) }
        describe 'in SPEC-COLL' do
          it 'does not allow more than 5 to be selected' do
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
        end
      end
    end

    describe 'when there are enough to be searchable' do
      let(:request_path) { new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS') }
      let(:holdings) { build(:searchable_holdings) }
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

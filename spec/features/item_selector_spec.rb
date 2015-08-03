require 'rails_helper'

describe 'Item Selector' do
  describe 'for single items' do
    before { stub_searchworks_api_json(build(:single_holding)) }
    it 'displays the item call number' do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')
      expect(page).to have_css('.control-label', text: 'Call number')
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
      it 'displays the selected item count' do
        expect(page).to have_css('span[data-items-counter]', text: '0 items selected')

        within('#item-selector') do
          check('ABC 123')
        end

        expect(page).to have_css('span[data-items-counter]', text: '1 items selected')

        within('#item-selector') do
          check('ABC 321')
        end

        expect(page).to have_css('span[data-items-counter]', text: '2 items selected')

        within('#item-selector') do
          uncheck('ABC 123')
        end

        expect(page).to have_css('span[data-items-counter]', text: '1 items selected')
      end
    end

    describe 'item limits' do
      describe 'for scans' do
        let(:request_path) { new_scan_path(item_id: '1234', origin: 'SAL3', origin_location: 'STACKS') }
        let(:holdings) { build(:sal3_holdings) }
        it 'is restricted to one selection via radio button' do
          within('#item-selector') do
            choose('ABC 321')
            choose('ABC 123')
            expect(field_labeled('ABC 321')).to_not be_checked
            expect(field_labeled('ABC 123')).to be_checked
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

          it 'adds and removes a message about the maximum being reached' do
            expect(page).to_not have_css('#max-items-reached.alert-danger')
            within('#item-selector') do
              check('ABC 123')
              check('ABC 456')
              check('ABC 789')
              check('ABC 012')
              check('ABC 345')
            end

            expect(page).to have_css(
              '#max-items-reached.alert-danger',
              text: 'You\'ve reached the maximum of 5 items per day.'
            )

            within('#item-selector') do
              uncheck('ABC 123')
            end

            expect(page).to_not have_css('#max-items-reached.alert-danger')
          end
        end
      end
    end

    describe 'when there are enough to be searchable' do
      let(:request_path) { new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS') }
      let(:holdings) { build(:searchable_holdings) }
      before { stub_current_user(create(:webauth_user)) }

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

      it 'persists items that are not currently visible due to filtering' do
        fill_in 'Planned date of use', with: Time.zone.today + 1.day
        within('#item-selector') do
          check('ABC 123')
          check('ABC 456')
          check('ABC 789')
        end

        within('#selected-items-filter') do
          fill_in 'Search item list', with: 'ABC 901'
        end

        within('#item-selector') do
          check('ABC 901')
        end

        click_button 'Send request'

        expect(page).to have_css('dd', text: 'ABC 123')
        expect(page).to have_css('dd', text: 'ABC 456')
        expect(page).to have_css('dd', text: 'ABC 789')
        expect(page).to have_css('dd', text: 'ABC 901')
      end
    end
  end

  describe 'when viewed under Back-Forward Cache', js: true do
    before do
      stub_current_user(create(:webauth_user))
      stub_searchworks_api_json(build(:searchable_holdings))
    end
    it 'still limits selections' do
      visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')

      fill_in 'Planned date of use', with: Time.zone.today + 1.day

      within('#item-selector') do
        check('ABC 123')
        check('ABC 456')
        check('ABC 789')
        check('ABC 012')
        check('ABC 345')
      end

      expect(page).to have_content('5 items selected')

      click_button 'Send request'

      expect(page).to have_content('Request complete')

      page.evaluate_script('window.history.back()') # Mimics back-button click

      expect(page).to have_content('5 items selected')

      expect(page).to have_css('.breadcrumb-pill', count: 5)

      within('#item-selector') do
        check('ABC 901')
        expect(field_labeled('ABC 901')).to_not be_checked
      end
    end
  end

  describe 'breadcrumb pills', js: true do
    before do
      stub_current_user(create(:webauth_user))
      stub_searchworks_api_json(build(:many_holdings))
    end

    it 'are addable and removable' do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')

      expect(page).to_not have_css('#breadcrumb-12345678', text: 'ABC 123')
      expect(page).to_not have_css('#breadcrumb-23456789', text: 'ABC 456')
      expect(page).to_not have_css('#breadcrumb-34567890', text: 'ABC 789')

      within('#item-selector') do
        check('ABC 123')
        check('ABC 456')
        check('ABC 789')
      end

      expect(page).to have_css('#breadcrumb-12345678', text: 'ABC 123')
      expect(page).to have_css('#breadcrumb-23456789', text: 'ABC 456')
      expect(page).to have_css('#breadcrumb-34567890', text: 'ABC 789')

      # Click the close button on the breadcrumb pill
      find('#breadcrumb-12345678 .close').click
      expect(page).to_not have_css('#breadcrumb-12345678', text: 'ABC 123')

      within('#item-selector') do
        expect(field_labeled('ABC 123')).to_not be_checked
        uncheck('ABC 456')
      end

      expect(page).to_not have_css('#breadcrumb-23456789', text: 'ABC 456')
    end
  end

  describe 'ad-hoc items', js: true do
    before do
      stub_current_user(create(:webauth_user))
      stub_searchworks_api_json(build(:searchable_holdings))
      visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')
    end

    it 'are addable and removable' do
      expect(page).to_not have_css('#breadcrumb-CUSTOMCALLNUMBER', text: 'CUSTOM .CALLNUMBER')

      fill_in 'ad_hoc_items', with: 'CUSTOM .CALLNUMBER'
      click_link 'Add'

      expect(page).to have_css('#breadcrumb-CUSTOMCALLNUMBER', text: 'CUSTOM .CALLNUMBER')

      # Click the close button on the breadcrumb pill
      find('#breadcrumb-CUSTOMCALLNUMBER .close').click

      expect(page).to_not have_css('#breadcrumb-CUSTOMCALLNUMBER', text: 'CUSTOM .CALLNUMBER')
    end

    it 'are not addable when the max-threshold has been reached' do
      expect(page).to_not have_css('[data-behavior="ad-hoc-items"] a.btn.disabled')
      within('#item-selector') do
        check('ABC 123')
        check('ABC 456')
        check('ABC 789')
        check('ABC 012')
        check('ABC 345')
      end

      expect(page).to have_css('.breadcrumb-pill', count: 5)
      expect(page).to have_css('[data-behavior="ad-hoc-items"] a.btn.disabled')

      within('#item-selector') do
        uncheck('ABC 123')
      end

      expect(page).to have_css('.breadcrumb-pill', count: 4)
      expect(page).to_not have_css('[data-behavior="ad-hoc-items"] a.btn.disabled')
    end

    it 'adds/removes a hidden field' do
      expect(page).to_not have_css('input[type="hidden"]#hidden-ZZZ123', visible: false)

      fill_in 'ad_hoc_items', with: 'ZZZ 123'
      click_link 'Add'

      expect(page).to have_css('input[type="hidden"]#hidden-ZZZ123', visible: false)

      # Click the close button on the ad-hoc-item's pill
      find('#breadcrumb-ZZZ123 .close').click

      expect(page).to_not have_css('input[type="hidden"]#hidden-ZZZ123', visible: false)
    end

    it 'are persisted' do
      fill_in 'Planned date of use', with: Time.zone.today + 1.day

      fill_in 'ad_hoc_items', with: 'ZZZ 321'
      click_link 'Add'
      fill_in 'ad_hoc_items', with: 'ZZZ 456'
      click_link 'Add'
      fill_in 'ad_hoc_items', with: 'ZZZ 999'
      click_link 'Add'

      # Click the close button on the last ad-hoc-item's pill
      find('#breadcrumb-ZZZ999 .close').click

      click_button 'Send request'

      expect(page).to have_css('dt', text: /additional item\(s\)/i)
      expect(page).to have_css('dd', text: 'ZZZ 321')
      expect(page).to have_css('dd', text: 'ZZZ 456')
      expect(page).to_not have_css('dd', text: 'ZZZ 999')
      expect(Request.last.ad_hoc_items).to eq(['ZZZ 321', 'ZZZ 456'])
    end
  end
end

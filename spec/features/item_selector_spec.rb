# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Item Selector' do
  before do
    stub_current_user(create(:sso_user))
  end

  describe 'for single items' do
    before { stub_bib_data_json(build(:single_holding)) }

    it 'displays the item call number' do
      visit new_page_path(item_id: '1234', origin: 'SAL3', origin_location: 'STACKS')
      expect(page).to have_css('.control-label', text: 'Call number')
      expect(page).to have_css('p', text: 'ABC 123')
      expect(page).not_to have_css('#item-selector')
    end
  end

  describe 'for multiple items', js: true do
    before do
      allow_any_instance_of(MediatedPage).to receive(:item_limit).and_return(5)
    end

    describe 'where there are not enough to be searchable' do
      let(:request_path) { new_page_path(item_id: '1234', origin: 'SAL3', origin_location: 'STACKS') }

      before do
        stub_bib_data_json(build(:multiple_holdings))
      end

      it 'displays the selected item count' do
        visit request_path

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

        before do
          stub_bib_data_json(build(:scannable_holdings))
        end

        it 'is restricted to one selection via radio button' do
          visit request_path

          within('#item-selector') do
            choose('ABC 321')
            choose('ABC 123')
            expect(find_field('ABC 321')).not_to be_checked
            expect(find_field('ABC 123')).to be_checked
          end
          expect(page).to have_content('1 items selected')
        end
      end

      describe 'for pages' do
        let(:request_path) { new_page_path(item_id: '1234', origin: 'SAL3', origin_location: 'STACKS') }

        before do
          stub_bib_data_json(build(:many_holdings))
        end

        it 'does not limit selection' do
          visit request_path

          within('#item-selector') do
            check('ABC 123')
            check('ABC 456')
            check('ABC 789')
            check('ABC 012')
            check('ABC 345')

            check('ABC 678')
            expect(find_field('ABC 678')).to be_checked
          end
          expect(page).to have_content('6 items selected')
        end
      end

      describe 'for aeon pages', js: true do
        let(:request_path) { new_aeon_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS') }

        before do
          stub_bib_data_json(build(:searchable_spec_holdings))

          visit request_path
          click_on 'Continue'
        end

        describe 'in SPEC-COLL' do
          it 'does not allow more than 5 to be selected' do
            within('#item-selector') do
              check('ABC 123')
              check('ABC 456')
              check('ABC 789')
              check('ABC 012')
              check('ABC 345')
              expect(page).to have_field('ABC 678', disabled: true)
              uncheck('ABC 345')
              expect(page).not_to have_field('ABC 678', disabled: true)
            end
          end

          it 'adds and removes a message about the maximum being reached' do
            expect(page).not_to have_css('#max-items-reached.alert-danger')
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

            expect(page).not_to have_css('#max-items-reached.alert-danger')
          end
        end
      end
    end

    describe 'when there are enough to be searchable' do
      let(:request_path) { new_mediated_page_path(item_id: '1234', origin: 'ART', origin_location: 'ARTLCKL') }

      before do
        stub_bib_data_json(build(:searchable_holdings))
        visit request_path
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
          expect(page).to have_field('ABC 901', disabled: true)
        end
      end

      it 'prevents users from selecting more than 5 items across different searches' do
        within('#item-selector') do
          check('ABC 123')
          check('ABC 456')
          check('ABC 789')
          check('ABC 012')
        end
        within('#selected-items-filter') do
          fill_in 'Search item list', with: 'ABC 901'
          check('ABC 901')

          fill_in 'Search item list', with: 'ABC'
          page.execute_script('$("#item-selector-search").blur()') # Bluring element so js events fire
        end

        within('#item-selector') do
          expect(page).to have_field('ABC 345', disabled: true)
        end
      end

      it 'persists items that are not currently visible due to filtering' do
        fill_in_required_date

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
      stub_bib_data_json(build(:searchable_holdings))
    end

    xit 'still limits selections' do
      skip('The CDN we load the date slider from seems to block Travis') if ENV['ci']

      visit new_mediated_page_path(item_id: '1234', origin: 'ART', origin_location: 'ARTLCKL')

      fill_in_required_date

      within('#item-selector') do
        check('ABC 123')
        check('ABC 456')
        check('ABC 789')
        check('ABC 012')
        check('ABC 345')
      end

      expect(page).to have_content('5 items selected')

      click_button 'Send request'

      expect_to_be_on_success_page

      page.driver.go_back # Mimics back-button click

      expect(page).to have_content('5 items selected')

      expect(page).to have_css('.breadcrumb-pill', count: 5)

      # temporarily disabled, see issue #719
      # within('#item-selector') do
      #   check('ABC 901')
      #   expect(find_field('ABC 901')).to_not be_checked
      # end
    end
  end

  describe 'breadcrumb pills', js: true do
    before do
      stub_bib_data_json(build(:many_holdings))
    end

    it 'are addable and removable' do
      visit new_page_path(item_id: '1234', origin: 'SAL3', origin_location: 'STACKS')

      expect(page).not_to have_css('#breadcrumb-12345678', text: 'ABC 123')
      expect(page).not_to have_css('#breadcrumb-23456789', text: 'ABC 456')
      expect(page).not_to have_css('#breadcrumb-34567890', text: 'ABC 789')

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
      expect(page).not_to have_css('#breadcrumb-12345678', text: 'ABC 123')

      within('#item-selector') do
        expect(find_field('ABC 123')).not_to be_checked
        uncheck('ABC 456')
      end

      expect(page).not_to have_css('#breadcrumb-23456789', text: 'ABC 456')
    end
  end

  describe 'checked out items', js: true do
    before do
      stub_bib_data_json(build(:checkedout_holdings))
      visit new_page_path(item_id: '1234', origin: 'SAL3', origin_location: 'STACKS')
    end

    it 'has the due date' do
      within('#item-selector') do
        expect(page).to have_css('.unavailable', text: 'Due 01/01/2015')
      end
    end

    it 'toggles the checked out note' do
      within('#item-selector') do
        expect(page).not_to have_css('.current-location-note')
        find('.unavailable', text: 'Due 01/01/2015').click
        expect(page).to have_css('.current-location-note')
      end
    end
  end

  describe 'public notes' do
    let(:request_path) { new_mediated_page_path(item_id: '1234', origin: 'ART', origin_location: 'ARTLCKL') }

    before do
      stub_bib_data_json(build(:searchable_holdings))
      visit request_path
    end

    it 'are hidden input fields' do
      within('#item-selector') do
        css_selector = 'input[name="request[public_notes][45678901]"][value="note for 45678901"]'
        expect(page).to have_css(css_selector, visible: :hidden)
        css_selector = 'input[name="request[public_notes][23456789]"][value="note for 23456789"]'
        expect(page).to have_css(css_selector, visible: :hidden)
      end
    end
  end

  def fill_in_required_date
    wait_for_ajax
    min_date = find_by_id('request_needed_date')['min']
    page.execute_script("$('#request_needed_date').prop('value', '#{min_date}')")
  end
end

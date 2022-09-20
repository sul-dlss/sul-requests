# frozen_string_literal: true

require 'rails_helper'

describe 'Creating an Aeon request', js: true do
  let(:user) { create(:webauth_user) }
  let(:api_json) { build(:special_collections_single_holding) }

  before do
    stub_current_user(user)
    stub_searchworks_api_json(api_json)
    visit new_aeon_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')
  end

  describe 'info modal' do
    it 'identifies the library of the item' do
      expect(page).to have_content 'Special Collections access'
    end

    it 'provides a link to the reading room info for the library of the item' do
      expect(page).to have_link 'Special Collections Reading Room service page', href: 'https://library.stanford.edu/spc/using-our-collections'
    end
  end

  describe 'for an item without a finding aid' do
    describe 'with a single holding' do
      describe 'info modal' do
        it 'provides instructions for the user to complete the request' do
          expect(page).to have_content 'Complete the request form'
        end

        it 'submits the request when dismissed' do
          click_on 'Continue'
          expect(page.current_host).to eq 'https://stanford.aeon.atlas-sys.com'
        end
      end

      describe 'request form' do
        it 'includes an identifier for the system making the request' do
          expect(page).to have_field(type: 'hidden', name: 'SystemID', with: 'sul-requests')
        end

        it 'uses the aeon form for a monograph' do
          expect(page).to have_field(type: 'hidden', name: 'WebRequestForm', with: 'GenericRequestMonograph')
          expect(page).to have_field(type: 'hidden', name: 'DocumentType', with: 'Monograph')
        end

        it 'preselects the correct reading room to fulfill the request' do
          expect(page).to have_field(type: 'hidden', name: 'Site', with: 'SPECUA')
        end

        it 'includes a link to view the item in searchworks' do
          expect(page).to have_field(type: 'hidden', name: 'ItemInfo1', with: 'https://searchworks.stanford.edu/view/1234')
        end

        it 'includes the origin location of the item' do
          expect(page).to have_field(type: 'hidden', name: 'Location', with: 'STACKS')
        end

        it 'includes the title of the item' do
          expect(page).to have_field(type: 'hidden', name: 'ItemTitle', with: 'Special Collections Item Title')
        end

        it 'includes the author of the item' do
          expect(page).to have_field(type: 'hidden', name: 'ItemAuthor', with: 'John Q. Public')
        end

        it 'includes the publication date of the item' do
          expect(page).to have_field(type: 'hidden', name: 'ItemDate', with: '2018')
        end

        it 'includes the request index' do
          expect(page).to have_field(type: 'hidden', name: 'Request', with: '1')
        end

        it 'includes the call number of the item' do
          expect(page).to have_field(type: 'hidden', name: 'CallNumber_1', with: 'ABC 123')
        end

        it 'includes the barcode of the item' do
          expect(page).to have_field(type: 'hidden', name: 'ItemNumber_1', with: '12345678')
        end
      end
    end

    describe 'with multiple holdings' do
      let(:api_json) { build(:special_collections_holdings) }

      describe 'info modal' do
        it 'provides instructions for the user to complete the request' do
          expect(page).to have_content 'Select the materials you would like access to'
        end

        it 'disappears when dismissed' do
          overlay = find_by_id('aeon-info-overlay')
          click_on 'Continue'
          expect(overlay).not_to be_visible
        end
      end

      describe 'item selector' do
        before do
          click_on 'Continue'
        end

        describe 'with no items selected' do
          it 'disables request indices' do
            expect(page).to have_field(type: 'hidden', name: 'Request', with: '1', disabled: true)
            expect(page).to have_field(type: 'hidden', name: 'Request', with: '2', disabled: true)
          end

          it 'disables item barcodes' do
            expect(page).to have_field(type: 'hidden', name: 'ItemNumber_1', with: '12345678', disabled: true)
            expect(page).to have_field(type: 'hidden', name: 'ItemNumber_2', with: '87654321', disabled: true)
          end
        end

        describe 'with items selected' do
          before do
            check 'request_barcodes_12345678'
            check 'request_barcodes_87654321'
          end

          it 'includes the index of each item' do
            expect(page).to have_field(type: 'hidden', name: 'Request', with: '1')
            expect(page).to have_field(type: 'hidden', name: 'Request', with: '2')
          end

          it 'includes the barcode of each item' do
            expect(page).to have_field(type: 'hidden', name: 'ItemNumber_1', with: '12345678')
            expect(page).to have_field(type: 'hidden', name: 'ItemNumber_2', with: '87654321')
          end

          it 'includes the call number of each item' do
            expect(page).to have_checked_field(name: 'CallNumber_1', with: 'ABC 123')
            expect(page).to have_checked_field(name: 'CallNumber_2', with: 'ABC 321')
          end
        end
      end
    end

    describe 'for an item with a finding aid' do
      let(:api_json) { build(:special_collections_finding_aid_holdings) }

      describe 'info modal' do
        it 'provides instructions for the user to complete the request' do
          expect(page).to have_content 'Review the Collection Guide in the Online Archive of California'
        end

        it 'visits the finding aid when dismissed' do
          click_on 'Continue'
          expect(page.current_host).to eq 'http://www.oac.cdlib.org'
        end
      end
    end
  end
end

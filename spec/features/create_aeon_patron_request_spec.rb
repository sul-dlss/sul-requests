# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating an Aeon patron request', :js do
  let(:user) { create(:sso_user) }
  let(:current_user) { CurrentUser.new(username: user.sunetid, patron_key: user.patron_key, shibboleth: true) }
  let(:bib_data) { :special_collections_single_holding }
  let(:patron) do
    instance_double(Folio::Patron, id: user.patron_key, username: 'auser', display_name: 'A User', exists?: true, email: nil,
                                   patron_description: 'faculty',
                                   patron_group_name: 'faculty',
                                   patron_group_id: '503a81cd-6c26-400f-b620-14c08943697c',
                                   blocked?: false, proxy_group_names: [], sponsor_names: [],
                                   allowed_request_types: ['Hold', 'Recall', 'Page'])
  end

  before do
    allow(Settings.ils.patron_model.constantize).to receive(:find_by).with(patron_key: user.patron_key).and_return(patron)
    login_as(current_user)
    stub_bib_data_json(build(bib_data))
  end

  describe 'reading room info' do
    before do
      visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SPEC-STACKS')
    end

    it 'identifies the library of the item' do
      expect(page).to have_content 'Special Collections access'
    end

    it 'provides a link to the reading room info for the library of the item' do
      expect(page).to have_link 'Special Collections Reading Room service page', href: 'https://library.stanford.edu/spc/using-our-collections'
    end

    context 'when the item is in SAL3 but will be paged to a reading room' do
      let(:bib_data) { :sal3_as_holding }

      it 'provides a link to the appropriate reading room' do
        visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SAL3-PAGE-AS')
        expect(page).to have_link 'Archive of Recorded Sound Reading Room service page', href: 'https://library.stanford.edu/libraries/archive-recorded-sound'
      end
    end

    context 'when there are multiple items' do
      let(:bib_data) { :special_collections_holdings }

      it 'identifies the reading room where the items will be prepared' do
        visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SPEC-STACKS')
        expect(page).to have_button('Continue', disabled: true)

        check 'patron_request_barcodes_12345678'
        check 'patron_request_barcodes_87654321'
        click_on 'Continue'
        expect(page).to have_content 'Use in: Special Collections & University Archives Reading Room'
      end
    end
  end

  context 'with an item without a finding aid' do
    before do
      visit new_patron_request_path(instance_hrid: 'a1234', origin_location_code: 'SPEC-STACKS')
    end

    context 'with a single holding' do
      it 'provides instructions for the user to complete the request' do
        expect(page).to have_content 'Complete the request form'
      end

      it 'goes to aeon when submitted' do
        click_on 'Continue'
        expect(page.current_host).to eq 'https://stanford.aeon.atlas-sys.com'
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
          expect(page).to have_field(type: 'hidden', name: 'Location', with: 'SPEC-STACKS')
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
      let(:bib_data) { :special_collections_holdings }

      describe 'item selector' do
        describe 'with no items selected' do
          it 'disables request indices' do
            expect(page).to have_button('Continue', disabled: true)
            expect(page).to have_field(type: 'hidden', name: 'Request', with: '1', disabled: true)
            expect(page).to have_field(type: 'hidden', name: 'Request', with: '2', disabled: true)
          end

          it 'disables item barcodes' do
            expect(page).to have_button('Continue', disabled: true)
            expect(page).to have_field(type: 'hidden', name: 'ItemNumber_1', with: '12345678', disabled: true)
            expect(page).to have_field(type: 'hidden', name: 'ItemNumber_2', with: '87654321', disabled: true)
          end
        end

        describe 'with items selected' do
          before do
            check 'patron_request_barcodes_12345678'
            check 'patron_request_barcodes_87654321'
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
            expect(page).to have_field(type: 'hidden', name: 'CallNumber_1', with: 'ABC 123')
            expect(page).to have_field(type: 'hidden', name: 'CallNumber_2', with: 'ABC 321')
          end
        end
      end
    end

    describe 'for an item with a finding aid' do
      let(:bib_data) { :special_collections_finding_aid_holdings }

      it 'provides instructions for the user to complete the request' do
        expect(page).to have_content 'Review the Collection Guide in the Online Archive of California'
      end

      it 'visits the finding aid when dismissed' do
        click_on 'Continue'
        expect(page.current_host).to eq 'https://oac.cdlib.org'
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a hold recall request' do
  before do
    stub_bib_data_json(build(:sal3_holdings))
  end

  let(:user) { create(:sso_user) }

  pending 'by an anonmyous user', :js do
    it 'requires the library id field' do
      form_path = new_hold_recall_path(
        item_id: '1234',
        barcode: '12345678',
        origin: 'SAL3',
        origin_location: 'SAL3-STACKS'
      )

      visit form_path

      click_on "I don't have a SUNet ID"

      expect(find_field('Library ID')['required']).to eq 'required'

      click_on 'Send request'

      expect(current_url).to include form_path
    end

    it 'is possible if a library id is filled out' do
      visit new_hold_recall_path(
        item_id: '1234',
        barcode: '12345678',
        origin: 'SAL3',
        origin_location: 'SAL3-STACKS'
      )
      click_on "I don't have a SUNet ID"

      fill_in 'Library ID', with: '1234567891'

      click_on 'Send request'

      expect(HoldRecall.last.user).to eq User.last
      expect(User.last.library_id).to eq '1234567891'
      expect_to_be_on_success_page
    end
  end

  describe 'by a SSO user' do
    let(:patron) do
      instance_double(Folio::Patron, id: nil, exists?: true, email: nil, patron_group_name: 'faculty',
                                     patron_group_id: 'bdc2b6d4-5ceb-4a12-ab46-249b9a68473e',
                                     ilb_eligible?: true)
    end

    before do
      stub_current_user(user)
      allow(Settings.ils.patron_model.constantize).to receive(:find_by).with(sunetid: user.sunetid).and_return(patron)
    end

    it 'is possible without filling in any user information' do
      visit new_hold_recall_path(item_id: '1234', barcode: '12345678', origin: 'SAL3', origin_location: 'SAL3-STACKS')
      first(:button, 'Send request').click

      expect(current_url).to eq successful_hold_recall_url(HoldRecall.last)
      expect_to_be_on_success_page
    end

    it 'stores barcode in the url in the barcodes array' do
      visit new_hold_recall_path(item_id: '1234', barcode: '12345678', origin: 'SAL3', origin_location: 'SAL3-STACKS')
      first(:button, 'Send request').click

      expect(HoldRecall.last.barcodes).to eq ['12345678']
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Fines Page' do
  let(:mock_client) { instance_double(FolioClient, ping: true) }
  let(:patron) do
    build(:patron_with_fines)
  end

  before do
    allow(FolioClient).to receive(:new) { mock_client }
    allow(patron).to receive(:checkouts).and_return([])
    login_as(CurrentUser.new(username: 'stub_user', patron_key: '513a9054-5897-11ee-8c99-0242ac120002', shibboleth: true))
    allow(Folio::Patron).to receive(:find_by).with(patron_key: '513a9054-5897-11ee-8c99-0242ac120002').and_return(patron)
  end

  context 'with fines' do
    it 'totals all the fines into the header' do
      visit fines_path

      expect(page).to have_text('Outstanding balance: $325.00')
    end

    it 'renders a list item for every fine' do
      visit fines_path

      within('ul.fines') do
        expect(page).to have_css('li', count: 1)
        expect(page).to have_css('li h3', text: 'Memes and the future of pop culture / by Marcel Danesi')
        expect(page).to have_css('li .status', text: 'Damaged material')
        expect(page).to have_css('li a', text: 'Contact library')
      end
    end
  end

  context 'with no fines' do
    let(:patron_info) do
      {
        'user' => { 'active' => true, 'manualBlocks' => [], 'blocks' => [] },
        'loans' => [],
        'holds' => [],
        'accounts' => []
      }
    end
    let(:patron) { Folio::Patron.new(patron_graphql_response: patron_info) }

    it 'does not render headers' do
      visit fines_path

      expect(page).to have_text('Fees and fines')
    end
  end
end

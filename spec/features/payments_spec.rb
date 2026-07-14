# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Payments History' do
  let(:mock_client) { instance_double(FolioClient, ping: true) }

  let(:patron) do
    build(:undergraduate_patron)
  end

  before do
    allow(FolioClient).to receive(:new) { mock_client }
    allow(patron).to receive(:checkouts).and_return([])
    login_as(CurrentUser.new(username: 'stub_user', patron_key: '513a9054-5897-11ee-8c99-0242ac120002', shibboleth: true))
    allow(Folio::Patron).to receive(:find_by).with(patron_key: '513a9054-5897-11ee-8c99-0242ac120002').and_return(patron)

    visit fines_path
  end

  context 'with payments' do
    it 'has a header for payment history' do
      expect(page).to have_css('h1', text: 'Fees and fines')
    end

    it 'renders a list item for every payment', :js do
      click_on 'Past'

      within('ul.payments') do
        expect(page).to have_css('li', count: 10)
        expect(page).to have_css('li h2',
                                 text: 'Aspects of twentieth century art : Picasso - Important paintings, ' \
                                       'watercolours, and new linocuts.')
        expect(page).to have_css('li .status', text: 'Lost item fee')
        expect(page).to have_css('li .fine-status', text: 'PAID')
      end
    end

    it 'is sortable', :js do
      click_on 'Past'

      within '#payments' do
        expect(page).to have_css('.dropdown-toggle', text: 'Sort by date paid')
        click_on 'Sort by date paid'

        within '[data-sortable-target="sortMenu"] .dropdown-menu' do
          click_on 'reason'
        end
        expect(page).to have_css('.dropdown-toggle', text: 'Sort by reason')
        expect(page).to have_css('.active[data-sortable-sort-param="status"]', visible: :all)

        within(first('ul.payments li')) do
          expect(page).to have_css('li .status', text: 'Damaged material')
        end
      end
    end
  end

  context 'with no payments' do
    let(:patron_info) do
      {
        'user' => { 'active' => true, 'manualBlocks' => [], 'blocks' => [], 'id' => 'userid' },
        'loans' => [],
        'holds' => [],
        'accounts' => []
      }
    end
    let(:patron) { Folio::Patron.new(patron_graphql_response: patron_info) }

    it 'does not load table', :js do
      click_on 'Past'

      expect(page).to have_css('span', text: 'There are no past fees or fines on this account.')
    end
  end
end

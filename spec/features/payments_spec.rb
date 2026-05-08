# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Payments History' do
  let(:mock_client) { instance_double(FolioClient, ping: true) }

  let(:patron) do
    build(:undergraduate_patron)
  end

  before do
    allow(FolioClient).to receive(:new) { mock_client }
    login_as(CurrentUser.new(username: 'stub_user', patron_key: '513a9054-5897-11ee-8c99-0242ac120002', shibboleth: true))
    allow(Folio::Patron).to receive(:find_by).with(patron_key: '513a9054-5897-11ee-8c99-0242ac120002').and_return(patron)

    visit fines_path
  end

  context 'with payments' do
    it 'has a header for payment history' do
      expect(page).to have_css('h2', text: 'History')
    end

    it 'renders a list item for every payment', :js do
      click_on 'Show history'

      within('ul.payments') do
        expect(page).to have_css('li', count: 10)
        expect(page).to have_css('li h3',
                                 text: 'Aspects of twentieth century art : Picasso - Important paintings, ' \
                                       'watercolours, and new linocuts.')
        expect(page).to have_css('li .nice_status', text: 'Lost item fee')
      end
    end

    it 'has content behind a payments toggle', :js do
      click_on 'Show history'

      within('ul.payments') do
        within(first('li')) do
          expect(page).to have_no_css('dl', visible: :visible)
          expect(page).to have_no_css('dt', text: 'Resolution', visible: :visible)
          click_on 'Expand'
          expect(page).to have_css('dl', visible: :visible)
          expect(page).to have_css('dt', text: 'Resolution', visible: :visible)
        end
      end
    end

    it 'is sortable', :js do
      skip 'need to rewrite the javascript'

      click_on 'Show history'

      within '#payments' do
        expect(page).to have_css('.dropdown-toggle', text: 'Sort (Date paid)')
        find('[data-sort="nice_status"]').click

        expect(page).to have_css('.dropdown-toggle', text: 'Sort (Reason)')
        expect(page).to have_css('.active[data-sort="nice_status"]', count: 2, visible: :all)

        within(first('ul.payments li')) do
          expect(page).to have_css('.nice_status', text: 'Damaged material')
        end
      end
    end
  end

  context 'with no payments' do
    let(:patron_info) do
      {
        'user' => { 'active' => true, 'manualBlocks' => [], 'blocks' => [] },
        'loans' => [],
        'holds' => [],
        'accounts' => []
      }
    end
    let(:patron) { Folio::Patron.new(patron_graphql_response: patron_info) }

    it 'does not load table', :js do
      click_on 'Show history'

      expect(page).to have_css('span', text: 'There is no history on this account')
    end
  end
end

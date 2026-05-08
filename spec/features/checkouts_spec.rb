# frozen_string_literal: true

require 'rails_helper'
require 'active_support'
require 'active_support/testing/time_helpers'

RSpec.describe 'Checkout Page' do
  include ActiveSupport::Testing::TimeHelpers

  let(:mock_client) { instance_double(FolioClient, ping: true, find_effective_loan_policy: {}) }

  let(:patron) do
    build(:sponsor_patron)
  end

  let(:loan_policy) { build(:grad_mono_loans) }

  before do
    # NOTE: tests that rely on LoanPolicy#due_date_after_renewal have to
    #       take place when Time.now is included in the fixture's
    #       loan policy schedule date range.
    travel_to Time.zone.parse('2023-06-13T07:00:00.000+00:00')
    allow(FolioClient).to receive(:new) { mock_client }
    allow(Folio::LoanPolicy).to receive(:new).and_return(loan_policy)
    login_as(CurrentUser.new(username: 'stub_user', patron_key: '513a9054-5897-11ee-8c99-0242ac120002', shibboleth: true))

    allow(Folio::Patron).to receive(:find_by).with(patron_key: '513a9054-5897-11ee-8c99-0242ac120002').and_return(patron)
  end

  it 'has checkout data' do
    visit checkouts_path

    expect(page).to have_css('ul.checkouts', count: 1)
    expect(page).to have_css('ul.checkouts li', count: 1)

    within(first('ul.checkouts li')) do
      expect(page).to have_css('.status', text: 'OK')
      expect(page).to have_css('.title', text: /Blue-collar Broadway/)
      expect(page).to have_css('.call_number', text: 'PN2277 .N7 W48 2015')
    end
  end

  context 'when a patron has recalls' do
    let(:patron) do
      build(:patron_with_recalls)
    end

    it 'has recall data' do
      visit checkouts_path

      expect(page).to have_css('ul.recalled-checkouts', count: 1)
      expect(page).to have_css('ul.recalled-checkouts li', count: 1)

      within(first('ul.recalled-checkouts li')) do
        expect(page).to have_css('.status', text: 'Recalled')
        expect(page).to have_css('.title', text: /Sci-fi architecture./)
        expect(page).to have_css('.call_number', text: 'NA1 .A16')
      end
    end
  end

  context 'when the checkout is renewable' do
    let(:loan_policy) do
      build(:grad_mono_loans,
            due_date: '2020-01-09T07:59:59.000+00:00',
            renewal_count: 0)
    end

    it 'has renewable status indicator' do
      visit checkouts_path

      expect(page).to have_css '.renewable-indicator .sul-icons'
    end
  end

  context 'when data is hidden behind a toggle' do
    let(:patron) do
      build(:patron_with_overdue_items)
    end

    it 'shows the renew data when the list item is expanded', :js do
      visit checkouts_path

      within('ul.checkouts li:nth-child(1)') do
        click_on 'Expand'
        expect(page).to have_css('dt', text: 'Can I renew?', visible: :visible)
      end
    end

    it 'shows other data when the list item is expanded', :js do
      visit checkouts_path

      within(first('ul.checkouts li')) do
        expect(page).to have_no_css('dl', visible: :visible)
        expect(page).to have_no_css('dt', text: 'Borrowed:', visible: :visible)
        click_on 'Expand'
        expect(page).to have_css('dl', visible: :visible)
        expect(page).to have_css('dt', text: 'Borrowed:', visible: :visible)
        expect(page).to have_css('dt', text: 'Days overdue:', visible: :visible)
        expect(page).to have_css('dd', text: /^\d+$/, visible: :visible)
        expect(page).to have_css('dt', text: 'Barcode:', visible: :visible)
        expect(page).to have_css('dd', text: '36105021987123', visible: :visible)
        expect(page).to have_css('dt', text: 'Fines accrued:', visible: :visible)
        expect(page).to have_css('dd', text: '$30.00', visible: :visible)
      end
    end
  end

  it 'translates the library code from the response into a name' do
    visit checkouts_path

    within(first('ul.checkouts li')) do
      expect(page).to have_css('dl dd', text: 'Green Library', visible: :all)
    end
  end

  it 'is sortable', :js do
    skip 'need to rewrite the javascript'
    visit checkouts_path

    within '#checkouts' do
      expect(page).to have_css('.dropdown-toggle', text: 'Sort (Due date)')
      find('[data-sort="title"]').click

      expect(page).to have_css('.dropdown-toggle', text: 'Sort (Title)')
      expect(page).to have_css('.active[data-sort="title"]', count: 2, visible: :all)

      within(first('ul.checkouts li')) do
        expect(page).to have_css('.title', text: /Blue-collar Broadway/)
      end
    end
  end

  context 'with a user who has no checkouts' do
    let(:patron_info) do
      {
        'user' => { 'active' => true, 'manualBlocks' => [], 'blocks' => [] },
        'loans' => [],
        'holds' => [],
        'accounts' => []
      }
    end

    let(:patron) { Folio::Patron.new(patron_graphql_response: patron_info) }

    it 'does not render table headers' do
      expect(page).to have_no_css('.list-header')
    end
  end
end

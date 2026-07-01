# frozen_string_literal: true

require 'rails_helper'
require 'active_support'
require 'active_support/testing/time_helpers'

RSpec.describe 'Checkout Page' do
  include ActiveSupport::Testing::TimeHelpers

  let(:mock_client) { instance_double(FolioClient, ping: true, find_effective_loan_policy: {}, find_overdue_fines_policy:) }

  let(:patron) do
    build(:sponsor_patron)
  end

  let(:find_overdue_fines_policy) { {} }
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
      expect(page).to have_text(/Blue-collar Broadway/)
      expect(page).to have_text('Call number: PN2277 .N7 W48 2015')
    end
  end

  context 'when a patron has recalls' do
    let(:patron) do
      build(:patron_with_recalls)
    end

    it 'has recall data' do
      visit checkouts_path

      expect(page).to have_css('ul.checkouts', count: 1)
      expect(page).to have_css('ul.checkouts li', count: 1)

      within(first('ul.checkouts li')) do
        expect(page).to have_text 'Recalled'
        expect(page).to have_text(/Sci-fi architecture./)
        expect(page).to have_text 'Call number: NA1 .A16'
      end
    end
  end

  context 'when a patron has overdue items' do
    let(:patron) do
      build(:patron_with_overdue_items)
    end
    let(:find_overdue_fines_policy) { { 'overdueFinePolicyId' => '12d0d55b-bcb9-473e-9bd7-1a54d52c007f' } }

    it 'has overdue messaging data' do
      visit checkouts_path

      expect(page).to have_css('ul.checkouts', count: 1)
      expect(page).to have_css('ul.checkouts li', count: 1)

      within(first('ul.checkouts li')) do
        expect(page).to have_text 'Overdue'
        expect(page).to have_text 'Accruing $1.00/day until returned'
        expect(page).to have_text(/Sci-fi architecture./)
        expect(page).to have_text 'Call number: NA1 .A16'
      end
    end
  end

  context 'when a patron has reserve items' do
    let(:loan_policy) { build(:reserves_loan_policy) }

    it 'has reserve messaging data' do
      visit checkouts_path

      expect(page).to have_css('ul.checkouts', count: 1)
      expect(page).to have_css('ul.checkouts li', count: 1)

      within(first('ul.checkouts li')) do
        expect(page).to have_text 'NOTE: This item must be returned to the Green Library'
        expect(page).to have_text 'Renew in person'
        expect(page).to have_text('Blue-collar Broadway')
        expect(page).to have_text 'Call number: PN2277 .N7 W48 2015'
      end
    end
  end

  context 'when the checkout is renewable' do
    let(:loan_policy) do
      build(:grad_mono_loans)
    end

    it 'has a renewal button' do
      visit checkouts_path

      expect(page).to have_button 'Renew'
    end
  end

  it 'shows other data in the footer' do
    visit checkouts_path

    within(first('ul.checkouts li')) do
      expect(page).to have_text 'Barcode: 36105212981729'
    end
  end

  it 'translates the library code from the response into a name' do
    visit checkouts_path

    within(first('ul.checkouts li')) do
      expect(page).to have_text 'Library: Green Library'
    end
  end

  it 'is sortable', :js do
    visit checkouts_path

    within '#checkouts' do
      expect(page).to have_css('.dropdown-toggle', text: 'Sort (Due date)')
      click_on 'Sort (Due date)'

      within '[data-sortable-target="sortMenu"] .dropdown-menu' do
        click_on 'Title'
      end

      expect(page).to have_css('.dropdown-toggle', text: 'Sort (Title)')
      expect(page).to have_css('.active[data-sortable-sort-param="title"]', visible: :all)

      within(first('ul.checkouts li')) do
        expect(page).to have_text(/Blue-collar Broadway/)
      end
    end
  end

  context 'with a user who has no checkouts' do
    let(:patron_info) do
      {
        'user' => { 'active' => true, 'manualBlocks' => [], 'blocks' => [], 'id' => 'userid' },
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

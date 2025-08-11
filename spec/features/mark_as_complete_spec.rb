# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Mark As Complete', :js do
  let(:user) { create(:superadmin_user) }
  let(:selected_items) do
    [
      double(:item, barcode: '34567890',
                    temporary_location: nil,
                    home_location: 'STACKS',
                    current_location: nil,
                    callnumber: 'ABC 123',
                    hold?: true,
                    pageable?: true,
                    mediateable?: true,
                    effective_location: build(:mediated_location),
                    permanent_location: build(:mediated_location),
                    material_type: build(:book_material_type),
                    loan_type: double(id: nil))
    ]
  end

  before do
    allow(Settings.ils.bib_model.constantize).to receive(:fetch).and_return(double(:bib_data, title: 'Test title',
                                                                                              items: selected_items))
    stub_current_user(user)
  end

  describe 'marking an item as complete' do
    let!(:mediated_page) do
      create(
        :mediated_patron_request_with_holdings,
        barcodes: %w(34567890),
        created_at: 1.day.from_now
      )
    end

    before { visit admin_path('ART') }

    it 'saves state for the request object' do
      expect(mediated_page).not_to be_marked_as_done

      click_on 'Toggle'
      click_on 'Mark as done'

      expect(page).to have_css('[data-behavior="mixed-approved-note"]', visible: :visible) # to wait for ajax

      expect(PatronRequest.find(mediated_page.id)).to be_marked_as_done
    end

    it 'disables the button' do
      click_on 'Toggle'

      button = page.find('button', text: 'Mark as done')
      expect(button).not_to be_disabled

      click_on 'Mark as done'
      expect(page).to have_no_css 'turbo-frame[busy]'

      button = page.find('button', text: 'Mark as done')
      expect(button).to be_disabled
    end

    it 'shows the mixed-approval label on the request row' do
      expect(page).to have_no_css('[data-behavior="mixed-approved-note"]', visible: :visible)

      click_on 'Toggle'

      click_on 'Mark as done'

      expect(page).to have_css('[data-behavior="mixed-approved-note"]', visible: :visible)
    end
  end

  describe 'a request that has already been marked as complete' do
    before do
      create(
        :mediated_patron_request_with_holdings,
        request_type: 'mediated/done',
        barcodes: %w(34567890),
        created_at: 1.day.from_now
      )
      visit admin_path('ART', done: 'true')
    end

    it 'has a disabled button' do
      click_on 'Toggle'

      button = page.find('button', text: 'Mark as done')
      expect(button).to be_disabled
    end

    it 'shows the mixed-approval label on the request row' do
      expect(page).to have_css('[data-behavior="mixed-approved-note"]', visible: :visible)
    end
  end
end

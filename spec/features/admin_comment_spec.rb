# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Comments', :js do
  let(:user) { create(:superadmin_user) }
  let(:request_status) do
    instance_double(ItemStatus, approved?: true, errored?: false, approver: 'bob', approval_time: '2023-05-31')
  end

  before do
    allow(Settings.ils.bib_model.constantize).to receive(:fetch).and_return(instance_double(Folio::Instance, items: []))
    stub_current_user(user)
    create(
      :mediated_patron_request_with_holdings,
      barcodes: %w(34567890),
      created_at: 1.day.from_now
    )
    visit admin_path('ART')
  end

  describe 'toggling admin comment form' do
    it 'begins with the form closed and allows the form to be toggled open' do
      click_on 'Toggle'

      expect(page).to have_css('.admin-comments')

      within('.admin-comments') do
        expect(page).to have_css('form#new_admin_comment', visible: :hidden)
        click_on 'Comment'
        expect(page).to have_css('form#new_admin_comment', visible: :visible)
      end
    end
  end

  describe 'saving comments' do
    it 'updates the page with the saved comment' do
      click_on 'Toggle'

      within('.admin-comments') do
        click_on 'Comment'
        expect(page).to have_css('form#new_admin_comment', visible: :visible)

        expect(page).to have_css('ul[data-behavior="admin-comments-list"]')
        expect(page).to have_no_css('ul[data-behavior="admin-comments-list"] li')

        fill_in 'Comment', with: 'An admin comment'
        click_on 'OK'

        expect(page).to have_css('ul[data-behavior="admin-comments-list"] li', text: 'An admin comment')
      end
    end
  end

  describe 'cancel button' do
    it 'clears and hides the form' do
      click_on 'Toggle'

      within('.admin-comments') do
        click_on 'Comment'
        expect(page).to have_css('form#new_admin_comment', visible: :visible)

        fill_in 'Comment', with: 'A comment I do not like'
        input = page.find('form#new_admin_comment input[type="text"]')
        expect(input['value']).to eq 'A comment I do not like'

        click_on 'Cancel'

        expect(page).to have_css('form#new_admin_comment', visible: :hidden)
        input = page.find('form#new_admin_comment input[type="text"]', visible: :hidden)
        expect(input['value']).to eq ''
      end
    end
  end
end

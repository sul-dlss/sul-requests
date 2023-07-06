# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Comments', js: true do
  let(:user) { create(:superadmin_user) }
  let(:holdings_relationship) { double(:relationship, where: selected_items, all: []) }
  let(:request_status) do
    instance_double(ItemStatus, approved?: true, errored?: false, approver: 'bob', approval_time: '2023-05-31')
  end
  let(:selected_items) do
    [
      double(:item, barcode: '34567890',
                    request_status:,
                    permanent_location: 'ART-STACKS',
                    temporary_location: nil,
                    home_location: 'ART-STACKS',
                    callnumber: 'ABC 123',
                    hold?: true)
    ]
  end

  before do
    allow(HoldingsRelationshipBuilder).to receive(:build).and_return(holdings_relationship)

    stub_searchworks_api_json(build(:searchable_holdings))
    stub_current_user(user)
    create(
      :mediated_page_with_holdings,
      user: create(:non_sso_user, name: 'Jim Doe ', email: 'jimdoe@example.com'),
      barcodes: %w(34567890),
      created_at: 1.day.from_now
    )
    visit admin_path('ART')
  end

  describe 'toggling admin comment form' do
    it 'begins with the form closed and allows the form to be toggled open' do
      within(first('[data-mediate-request]')) do
        page.find('a.mediate-toggle').click
      end

      within('.admin-comments') do
        expect(page).to have_css('form#new_admin_comment', visible: :hidden)
        click_button 'Comment'
        expect(page).to have_css('form#new_admin_comment', visible: :visible)
      end
    end
  end

  describe 'saving comments' do
    it 'updates the page with the saved comment' do
      within(first('[data-mediate-request]')) do
        page.find('a.mediate-toggle').click
      end

      within('.admin-comments') do
        click_button 'Comment'
        expect(page).to have_css('form#new_admin_comment', visible: :visible)

        expect(page).to have_css('ul[data-behavior="admin-comments-list"]')
        expect(page).not_to have_css('ul[data-behavior="admin-comments-list"] li')

        fill_in 'Comment', with: 'An admin comment'
        click_button 'OK'

        expect(page).to have_css('ul[data-behavior="admin-comments-list"] li', text: 'An admin comment')
      end
    end
  end

  describe 'cancel button' do
    it 'clears and hides the form' do
      within(first('[data-mediate-request]')) do
        page.find('a.mediate-toggle').click
      end

      within('.admin-comments') do
        click_button 'Comment'
        expect(page).to have_css('form#new_admin_comment', visible: :visible)

        fill_in 'Comment', with: 'A comment I do not like'
        input = page.find('form#new_admin_comment input[type="text"]')
        expect(input['value']).to eq 'A comment I do not like'

        click_link 'Cancel'

        expect(page).to have_css('form#new_admin_comment', visible: :hidden)
        input = page.find('form#new_admin_comment input[type="text"]', visible: :hidden)
        expect(input['value']).to eq ''
      end
    end
  end
end

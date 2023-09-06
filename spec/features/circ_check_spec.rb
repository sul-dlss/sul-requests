# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Circ Check app', js: true do
  let(:client) { FolioGraphqlClient.new }

  before do
    allow(FolioGraphqlClient).to receive(:new).and_return(client)
    allow(client).to receive(:circ_check).with(barcode: '1234567890').and_return(response.with_indifferent_access)
  end

  context 'when the barcode is checked out' do
    let(:response) do
      {
        data: {
          items: [{
            barcode: '1234567890',
            status: { name: 'Checked out' },
            dueDate: '2020-01-01T12:00:00Z'
          }]
        }
      }
    end

    it 'shows a success toast' do
      visit '/circ-check'

      fill_in 'barcode', with: '1234567890'
      click_button 'Check'

      expect(page).to have_content('✅ 1234567890')
      expect(page).to have_content('Due: Jan 1 2020')
    end
  end

  context 'when the barcode is aged to lost' do
    let(:response) do
      {
        data: {
          items: [{
            barcode: '1234567890',
            status: { name: 'Aged to lost' },
            dueDate: '2020-01-01T12:00:00Z'
          }]
        }
      }
    end

    it 'shows a success toast' do
      visit '/circ-check'

      fill_in 'barcode', with: '1234567890'
      click_button 'Check'

      expect(page).to have_content('✅ 1234567890')
      expect(page).to have_content('Due: Jan 1 2020')
    end
  end

  context 'when the barcode is not checked out' do
    let(:response) do
      {
        data: {
          items: [{
            barcode: '1234567890',
            status: { name: 'Withdrawn' }
          }]
        }
      }
    end

    it 'shows a success toast' do
      visit '/circ-check'

      fill_in 'barcode', with: '1234567890'
      click_button 'Check'

      expect(page).to have_content('⛔ 1234567890')
      expect(page).to have_content('Status: Withdrawn')
    end
  end

  context 'when the barcode does not exist' do
    let(:response) do
      {
        'data' => {
          'items' => []
        }
      }
    end

    it 'raises an error' do
      visit '/circ-check'

      fill_in 'barcode', with: '1234567890'
      click_button 'Check'

      expect(page).to have_content('Barcode does not exist: 1234567890')
    end
  end
end

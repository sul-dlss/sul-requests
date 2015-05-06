require 'rails_helper'

describe 'Create Scan Request' do
  describe 'by a webauth user' do
    before { stub_current_user(create(:webauth_user)) }
    it 'should be possible' do
      visit new_scan_path(item_id: '1234', origin: 'SAL3', origin_location: 'STACKS')

      page_range = '1-3, 7, 19-29'
      fill_in 'Page range', with: page_range

      article_title = 'The title of the Article'
      fill_in 'Article title', with: article_title

      authors = 'Stanford, Jane'
      fill_in 'Author(s)', with: authors

      click_button 'Send request'

      expect(page).to have_css('h1#dialogTitle', 'Request complete')

      scan = Scan.last
      expect(scan.item_id).to eq '1234'
      expect(scan.origin).to eq 'SAL3'
      expect(scan.origin_location).to eq 'STACKS'
      expect(scan.data['page_range']).to eq page_range
      expect(scan.data['section_title']).to eq article_title
      expect(scan.data['authors']).to eq authors
    end
  end
  describe 'by non webauth user' do
    it 'should provide a link to page the item' do
      visit new_scan_path(item_id: '1234', origin: 'SAL3', origin_location: 'STACKS')

      expect(page).to have_link 'Request the physical item'

      click_link 'Request the physical item'

      expect(page).to have_css('h1#dialogTitle', 'Request delivery to campus library')
      expect(current_url).to eq new_page_url(item_id: '1234', origin: 'SAL3', origin_location: 'STACKS')
    end
  end

  describe 'selecting barcodes' do
    before do
      stub_current_user(create(:webauth_user))
      stub_searchworks_api_json(build(:sal3_holdings))
    end
    it 'should persist to the database' do
      visit new_scan_path(item_id: '1234', origin: 'SAL3', origin_location: 'STACKS')

      within('#item-selector') do
        check('ABC 123')
      end

      click_button 'Send request'

      expect(page).to have_css('h1#dialogTitle', text: 'Request complete')

      expect(Scan.last.barcodes).to eq(%w(12345678))
    end
  end
end

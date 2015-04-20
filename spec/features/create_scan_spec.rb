require 'rails_helper'

describe 'Create Scan Request' do
  describe 'by a webauth user' do
    before { stub_current_user }
    it 'should be possible' do
      visit new_scan_path(item_id: '1234', origin: 'SAL3', origin_location: 'STACKS')

      page_range = '1-3, 7, 19-29'
      fill_in 'Page range', with: page_range

      article_title = 'The title of the Article'
      fill_in 'Article title', with: article_title

      authors = 'Stanford, Jane'
      fill_in 'Author(s)', with: authors

      click_button 'Create Scan'

      expect(page).to have_css('.alert-success', text: 'Scan request was successfully created.')

      scan = Scan.last
      expect(scan.item_id).to eq '1234'
      expect(scan.origin).to eq 'SAL3'
      expect(scan.origin_location).to eq 'STACKS'
      expect(scan.data['page_range']).to eq page_range
      expect(scan.data['section_title']).to eq article_title
      expect(scan.data['authors']).to eq authors
    end
  end
end

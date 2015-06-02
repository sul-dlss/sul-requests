require 'rails_helper'

describe 'Create Scan Request' do
  before do
    allow_any_instance_of(ScansController).to receive(:illiad_query).and_return('http://illiad.ill')
    stub_searchworks_api_json(build(:sal3_holdings))
  end
  describe 'by a webauth user' do
    before do
      stub_current_user(create(:webauth_user))
    end
    it 'should be possible' do
      visit new_scan_path(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS')

      page_range = '1-3, 7, 19-29'
      fill_in 'Page range', with: page_range

      article_title = 'The title of the Article'
      fill_in 'Article title', with: article_title

      authors = 'Stanford, Jane'
      fill_in 'Author(s)', with: authors

      click_button 'Send request'

      scan = Scan.last
      expect(scan.item_id).to eq '12345'
      expect(scan.origin).to eq 'SAL3'
      expect(scan.origin_location).to eq 'STACKS'
      expect(scan.data['page_range']).to eq page_range
      expect(scan.data['section_title']).to eq article_title
      expect(scan.data['authors']).to eq authors
    end
  end
  describe 'by non webauth user' do
    it 'should provide a link to page the item' do
      visit new_scan_path(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS')

      expect(page).to have_link 'Request the physical item'

      click_link 'Request the physical item'

      expect(page).to have_css('h1#dialogTitle', 'Request delivery to campus library')
      expect(current_url).to eq new_page_url(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS')
    end
  end

  describe 'selecting barcodes' do
    before do
      stub_current_user(create(:webauth_user))
      stub_searchworks_api_json(build(:sal3_holdings))
    end

    it 'should persist to the database and offer up an illiad url' do
      visit new_scan_path(item_id: '12345', origin: 'SAL3', origin_location: 'STACKS')

      within('#item-selector') do
        check('ABC 123')
      end

      click_button 'Send request'

      expect(Scan.last.barcodes).to eq(%w(12345678))

      expect('http://illiad.ill/').to eq(current_url)
    end
  end
end

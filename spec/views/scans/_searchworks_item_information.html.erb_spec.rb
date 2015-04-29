require 'rails_helper'

describe 'scans/_searchworks_item_information.html.erb' do
  before do
    assign(:scan, scan)
    render
  end
  describe 'persisted scans' do
    let(:scan) { create(:scan) }
    it 'should display the stored item title in an h2' do
      expect(rendered).to have_css('h2', text: 'Title for Scan 1234')
    end
  end
  describe 'non-persisted scans' do
    let(:scan) { Scan.new(item_id: '2824966') }
    it 'should display the API fetched item title in an h2' do
      expect(rendered).to have_css('h2', text: /When do you need an antacid\? : a burning question/)
    end
  end
end

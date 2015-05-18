require 'rails_helper'

describe 'shared/_searchworks_item_information.html.erb' do
  before do
    allow(view).to receive_messages(request: request)
    render
  end
  describe 'persisted objects' do
    let(:request) { create(:scan) }
    it 'should display the stored item title in an h2' do
      expect(rendered).to have_css('h2', text: 'Title for Scan 1234')
    end
  end
  describe 'non-persisted scans' do
    let(:request) { Scan.new(item_id: '2824966') }
    it 'should display the API fetched item title in an h2', allow_apis: true do
      expect(rendered).to have_css('h2', text: /When do you need an antacid\? : a burning question/)
    end
  end
end

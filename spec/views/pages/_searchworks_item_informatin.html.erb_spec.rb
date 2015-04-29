require 'rails_helper'

describe 'pages/_searchworks_item_information.html.erb' do
  before do
    assign(:page, page)
    render
  end
  describe 'persisted pages' do
    let(:page) { create(:page) }
    it 'should display the stored item title in an h2' do
      expect(Capybara.string(rendered)).to have_css('h2', text: 'Title for Page 1234')
    end
  end
  describe 'non-persisted pages' do
    let(:page) { Page.new(item_id: '2824966') }
    it 'should display the API fetched item title in an h2' do
      expect(Capybara.string(rendered)).to have_css('h2', text: /When do you need an antacid\? : a burning question/)
    end
  end
end

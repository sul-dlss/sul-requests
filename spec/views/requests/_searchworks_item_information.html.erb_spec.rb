# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'requests/_searchworks_item_information.html.erb' do
  before do
    allow(view).to receive_messages(current_request: request)
  end

  describe 'persisted objects' do
    let(:request) { create(:scan, :with_holdings) }

    before { render }

    it 'displays the stored item title in an h2' do
      expect(rendered).to have_css('h2', text: 'SAL Item Title')
    end
  end

  describe 'non-persisted scans' do
    let(:request) { Scan.new(item_id: '2824966') }

    before do
      allow(Settings.ils.bib_model.constantize).to receive(:fetch)
        .and_return(double(title: 'When do you need an antacid? : a burning question'))
      render
    end

    it 'displays the API fetched item title in an h2' do
      expect(rendered).to have_css('h2', text: /When do you need an antacid\? : a burning question/)
    end
  end
end

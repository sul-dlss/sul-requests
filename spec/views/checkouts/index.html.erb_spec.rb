# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'checkouts/index' do
  let(:patron) { instance_double(Folio::Patron, remaining_checkouts: nil) }

  before do
    stub_template 'shared/_navigation.html.erb' => 'Navigation'
    without_partial_double_verification do
      allow(view).to receive(:patron_or_group).and_return(patron)
    end

    assign(:checkouts, [])
    assign(:requests, [])
  end

  it 'shows the number of checkouts' do
    render

    expect(rendered).to include('<h2>Checked out: 0</h2>')
  end

  it 'does not show headers for zero checkouts' do
    render

    expect(rendered).not_to include('<div class="list-header">')
  end

  context 'with a fee borrower' do
    before do
      allow(patron).to receive(:remaining_checkouts).and_return(25)
    end

    it 'shows the number of checkouts remaining' do
      render

      expect(rendered).to include('<h2>Checked out: 0 (25 remaining)</h2>')
    end
  end
end

require 'rails_helper'

describe 'Mediation table' do
  let(:top_level_columns) { 4 }
  before do
    stub_current_user(create(:superadmin_user))
    stub_searchworks_api_json(build(:searchable_holdings))
    create(:mediated_page_with_holdings, user: create(:non_webauth_user), barcodes: %w(12345678 23456789))
    create(
      :mediated_page_with_holdings,
      user: create(:non_webauth_user, name: 'Joe Doe ', email: 'joedoe@example.com'),
      barcodes: %w(34567890 45678901)
    )
  end

  it 'has toggleable rows that display holdings', js: true do
    visit admin_path('SPEC-COLL')
    expect(page).to have_css('[data-mediate-request]', count: 2)
    expect(page).to have_css('tbody tr', count: 2)
    within(first('[data-mediate-request]')) do
      expect(page).to have_css('td', count: top_level_columns)
      page.find('a.mediate-toggle').click
    end
    expect(page).to have_css("tbody td[colspan='#{top_level_columns}'] table")
    within("tbody td[colspan='#{top_level_columns}'] table") do
      expect(page).to have_css('td button', text: 'Approve', count: 2)
      expect(page).to have_css('td button', text: 'Deny', count: 2)
      expect(page).to have_css('td', text: 'STACKS', count: 2)
      expect(page).to have_css('td', text: 'ABC 123')
      expect(page).to have_css('td', text: 'ABC 456')
    end
  end
end

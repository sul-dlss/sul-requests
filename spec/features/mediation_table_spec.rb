require 'rails_helper'

describe 'Mediation table', js: true do
  let(:top_level_columns) { 6 }
  before do
    stub_current_user(create(:superadmin_user))
    stub_searchworks_api_json(build(:searchable_holdings))
    create(
      :mediated_page_with_holdings,
      user: create(:non_webauth_user),
      barcodes: %w(12345678 23456789),
      created_at: Time.zone.now - 1.day
    )
    create(
      :mediated_page_with_holdings,
      user: create(:non_webauth_user, name: 'Joe Doe ', email: 'joedoe@example.com'),
      barcodes: %w(34567890 45678901)
    )
    create(
      :mediated_page_with_holdings,
      user: create(:non_webauth_user, name: 'Jim Doe ', email: 'jimdoe@example.com'),
      barcodes: %w(34567890),
      ad_hoc_items: ['ABC 123'],
      created_at: Time.zone.now + 1.day
    )
  end

  it 'has toggleable rows that display holdings' do
    visit admin_path('SPEC-COLL')
    expect(page).to have_css('[data-mediate-request]', count: 3)
    expect(page).to have_css('tbody tr', count: 3)
    within(first('[data-mediate-request]')) do
      expect(page).to have_css('td', count: top_level_columns)
      page.find('a.mediate-toggle').click
    end
    expect(page).to have_css("tbody td[colspan='#{top_level_columns}'] table")
    within("tbody td[colspan='#{top_level_columns}'] table") do
      expect(page).to have_css('td button', text: 'Approve', count: 2)
      expect(page).to have_css('td', text: 'STACKS', count: 2)
      expect(page).to have_css('td', text: 'ABC 123')
      expect(page).to have_css('td', text: 'ABC 456')
    end
  end

  it 'has sortable columns' do
    visit admin_path('SPEC-COLL')

    within '.mediation-table tbody' do
      expect(page).to have_content(/Jane Stanford.*Joe Doe.*Jim Doe/)
    end

    click_link 'Requested on'

    within '.mediation-table tbody' do
      expect(page).to have_content(/Jim Doe.*Joe Doe.*Jane Stanford/)
    end
  end
end

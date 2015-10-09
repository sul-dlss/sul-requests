require 'rails_helper'

describe 'Mediation table', js: true do
  let(:top_level_columns) { 7 }
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
    visit admin_path('SPEC-COLL')
  end

  it 'has toggleable rows that display holdings' do
    expect(page).to have_css('[data-mediate-request]', count: 3)
    expect(page).to have_css('tbody tr', count: 3)
    within(first('[data-mediate-request]')) do
      expect(page).to have_css('td', count: top_level_columns)
      page.find('a.mediate-toggle').trigger('click')
    end
    expect(page).to have_css("tbody td[colspan='#{top_level_columns}'] table")
    within("tbody td[colspan='#{top_level_columns}'] table") do
      expect(page).to have_css('td button', text: 'Approve', count: 2)
      expect(page).to have_css('td', text: 'STACKS', count: 2)
      expect(page).to have_css('td', text: 'ABC 123')
      expect(page).to have_css('td', text: 'ABC 456')
    end
  end

  it 'has holdings that can be approved' do
    within(first('[data-mediate-request]')) do
      page.find('a.mediate-toggle').trigger('click')
    end

    within('tbody td table tbody') do
      expect(page).to_not have_css('tr.approved')
      within(first('tr')) do
        expect(page).to have_css('td button', text: 'Approve')
        expect(page).to_not have_css('td', text: 'Added to pick list', visible: true)
        expect(page).to_not have_content('super-admin')
        click_button('Approve')
      end
      expect(page).to have_css('tr.approved')
      expect(page).to have_css('td button', text: 'Approved')

      within(first('tr')) do
        expect(page).to have_css('td', text: 'Added to pick list', visible: true)
        expect(page).to have_css('td', text: /super-admin - \d{4}-\d{2}-\d{2}/)
      end
    end

    # and check that it is persisted
    visit admin_path('SPEC-COLL')

    within(first('[data-mediate-request]')) do
      page.find('a.mediate-toggle').trigger('click')
    end

    expect(page).to have_css('tr.approved')
    expect(page).to have_css('td button', text: 'Approved')
  end

  it 'indicates when all items in a request have been approved' do
    within(first('[data-mediate-request]')) do
      expect(page).to_not have_css('[data-behavior="all-approved-note"]', text: 'Done')
      page.find('a.mediate-toggle').trigger('click')
    end

    within('tbody td table tbody') do
      within(all('tr').first) do
        click_button('Approve')
      end

      within(all('tr').last) do
        click_button('Approve')
      end
    end

    within(first('[data-mediate-request]')) do
      expect(page).to have_css('[data-behavior="all-approved-note"]', text: 'Done')
    end
  end

  it 'has sortable columns' do
    within '.mediation-table tbody' do
      expect(page).to have_content(/Jane Stanford.*Joe Doe.*Jim Doe/)
    end

    click_link 'Requested on'

    within '.mediation-table tbody' do
      expect(page).to have_content(/Jim Doe.*Joe Doe.*Jane Stanford/)
    end
  end
end

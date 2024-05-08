# frozen_string_literal: true

FactoryBot.define do
  factory :page_patron_request, class: 'PatronRequest' do
    request_type { 'pickup' }
    instance_hrid { 'a12345' }
    origin_location_code { 'SAL3-STACKS' }
    service_point_code { 'GREEN-LOAN' }
    bib_data { build(:sal3_holding) }
    barcodes { ['87654321'] }
    patron { build(:patron) }
  end

  factory :mediated_patron_request, class: 'PatronRequest' do
    request_type { 'mediated' }
    instance_hrid { 'a1234' }
    origin_location_code { 'ART-LOCKED-LARGE' }
    service_point_code { 'ART' }
    needed_date { Time.zone.today }
    bib_data { build(:single_mediated_holding) }
    barcodes { ['12345678'] }
    patron { build(:patron) }
  end

  factory :page_mp_mediated_patron_request, parent: :mediated_patron_request do
    request_type { 'mediated' }
    instance_hrid { 'a1234' }
    origin_location_code { 'SAL3-PAGE-MP' }
    service_point_code { 'EARTH-SCI' }
    item_title { 'Title of MediatedPage 1234' }
    needed_date { Time.zone.today }
    bib_data { build(:page_mp_holdings) }
    patron { build(:patron) }
  end

  factory :mediated_patron_request_with_holdings, parent: :mediated_patron_request do
    request_type { 'mediated' }
    instance_hrid { 'a1234' }
    origin_location_code { 'ART-LOCKED-LARGE' }
    service_point_code { 'ART' }
    needed_date { Time.zone.today }
    patron { build(:patron) }
    bib_data { build(:searchable_holdings) }
  end
end

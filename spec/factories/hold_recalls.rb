# frozen_string_literal: true

FactoryBot.define do
  factory :hold_recall do
    item_id { '1234' }
    origin { 'GREEN' }
    origin_location { 'GRE-STACKS' }
    requested_barcode { '36105212925395' }
    destination { 'GREEN' }
    item_title { 'Title of HoldRecall 1234' }
    needed_date { Time.zone.today }
  end

  factory :hold_recall_with_holdings, class: 'HoldRecall' do
    item_id { '1234' }
    origin { 'SAL3' }
    origin_location { 'SAL3-STACKS' }
    requested_barcode { '12345678' }
    destination { 'GREEN' }
    item_title { 'Title of HoldRecall 1234' }
    needed_date { Time.zone.today }
    bib_data { FactoryBot.build(:sal3_holdings) }
  end

  factory :hold_recall_with_holdings_folio, class: 'HoldRecall' do
    item_id { '1234' }
    origin { 'SAL3' }
    origin_location { 'SAL3-STACKS' }
    requested_barcode { '12345678' }
    destination { 'GREEN-LOAN' }
    item_title { 'Title of HoldRecall 1234' }
    needed_date { Time.zone.today }
    bib_data { FactoryBot.build(:sal3_holdings) }
  end

  factory :hold_recall_checkedout, class: 'HoldRecall' do
    item_id { '1234' }
    origin { 'SAL3' }
    origin_location { 'STACKS' }
    requested_barcode { '87654321' }
    destination { 'GREEN' }
    needed_date { Time.zone.today }
    bib_data { FactoryBot.build(:checkedout_holdings) }
  end

  factory :hold_on_order, parent: :hold_recall do
    item_id { '1234' }
    origin { 'ZOMBIE' }
    origin_location { 'STACKS' }
    destination { 'ART' }
    bib_data { build(:on_order_instance) }
  end
end

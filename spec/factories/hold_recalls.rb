# frozen_string_literal: true

FactoryBot.define do
  factory :hold_recall do
    item_id { '1234' }
    origin { 'GREEN' }
    origin_location { 'STACKS' }
    requested_barcode { '36105212925395' }
    destination { 'GREEN' }
    item_title { 'Title of HoldRecall 1234' }
    needed_date { Time.zone.today }
  end

  factory :hold_recall_with_holdings, class: HoldRecall do
    item_id { '1234' }
    origin { 'SAL3' }
    origin_location { 'STACKS' }
    requested_barcode { '12345678' }
    destination { 'GREEN' }
    item_title { 'Title of HoldRecall 1234' }
    needed_date { Time.zone.today }

    after(:build) do |hold_recall|
      class << hold_recall
        def searchworks_item
          @searchworks_item ||= FactoryBot.build(:sal3_stacks_multi_holdings_searchworks_item, request: self)
        end
      end
    end
  end
end

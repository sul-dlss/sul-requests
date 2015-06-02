FactoryGirl.define do
  factory :scan do
    item_id '12345'
    origin 'SAL3'
    origin_location 'STACKS'
    item_title 'Title for Scan 12345'
  end

  factory :scan_with_holdings, class: Scan do
    item_id '12345'
    origin 'SAL3'
    origin_location 'STACKS'

    after(:build) do |scan|
      class << scan
        def searchworks_item
          FactoryGirl.build(:sal3_stacks_multi_holdings_searchworks_item)
        end
      end
    end
  end
end

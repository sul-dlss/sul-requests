FactoryGirl.define do
  factory :scan do
    item_id '1234'
    origin 'SAL3'
    origin_location 'STACKS'
    item_title 'Title for Scan 1234'
  end

  factory :scan_with_holdings, class: Scan do
    item_id '1234'
    origin 'SAL3'
    origin_location 'STACKS'

    after(:build) do |page|
      class << page
        def searchworks_item
          FactoryGirl.build(:sal3_stacks_multi_holdings_searchworks_item)
        end
      end
    end
  end
end

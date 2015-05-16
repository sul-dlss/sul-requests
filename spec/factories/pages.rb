FactoryGirl.define do
  factory :page do
    item_id '1234'
    origin 'GREEN'
    origin_location 'STACKS'
    destination 'BIOLOGY'
    item_title 'Title for Page 1234'
  end

  factory :page_with_holdings, class: Page do
    item_id '1234'
    origin 'GREEN'
    origin_location 'STACKS'
    destination 'BIOLOGY'

    after(:build) do |page|
      class << page
        def searchworks_item
          FactoryGirl.build(:green_stacks_multi_holdings_searchworks_item)
        end
      end
    end
  end
end

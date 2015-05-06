FactoryGirl.define do
  factory :request do
    item_id '12345'
    origin 'BIOLOGY'
    origin_location 'STACKS'
    item_title 'Title for Request 12345'
  end

  factory :request_with_holdings, class: Request do
    item_id '12345'
    origin 'GREEN'
    origin_location 'STACKS'

    after(:build) do |request|
      class << request
        def searchworks_item
          FactoryGirl.build(:green_stacks_searchworks_item)
        end
      end
    end
  end

  factory :request_with_multiple_holdings, class: Request do
    item_id '12345'
    origin 'GREEN'
    origin_location 'STACKS'

    after(:build) do |request|
      class << request
        def searchworks_item
          FactoryGirl.build(:green_stacks_multi_holdings_searchworks_item)
        end
      end
    end
  end
end

FactoryBot.define do
  factory :request do
    item_id '12345'
    origin 'BIOLOGY'
    origin_location 'STACKS'
    item_title 'Title for Request 12345'

    after(:build) do |request|
      class << request
        def symphony_response_data
          FactoryBot.build(:symphony_page_with_single_item)
        end
      end
    end
  end

  factory :request_with_holdings, class: Request do
    item_id '12345'
    origin 'GREEN'
    origin_location 'STACKS'

    after(:build) do |request|
      class << request
        def searchworks_item
          @searchworks_item ||= FactoryBot.build(:green_stacks_searchworks_item, request: self)
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
          @searchworks_item ||= FactoryBot.build(:green_stacks_multi_holdings_searchworks_item, request: self)
        end
      end
    end
  end

  factory :request_with_symphony_errors, class: Request do
    item_id '12345'
    origin 'SAL3'
    origin_location 'STACKS'
    item_title 'Title for Request 12345'

    after(:build) do |request|
      class << request
        def symphony_response_data
          FactoryBot.build(:symphony_scan_with_multiple_items)
        end
      end
    end
  end
end

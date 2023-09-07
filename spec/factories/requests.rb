# frozen_string_literal: true

FactoryBot.define do
  factory :request do
    item_id { '123456' }
    location { 'SAL3-STACKS' }
    item_title { 'Title for Request 123456' }
    bib_data { FactoryBot.build(:multiple_holdings) }

    after(:build) do |request|
      class << request
        def symphony_response_data
          FactoryBot.build(:symphony_page_with_single_item)
        end
      end
    end
  end

  factory :request_with_holdings, class: 'Request' do
    item_id { '12345' }
    location { 'SAL3-STACKS' }
    bib_data { FactoryBot.build(:single_holding) }
  end

  factory :request_with_multiple_holdings, class: 'Request' do
    item_id { '12345' }
    location { 'SAL3-STACKS' }
    bib_data { FactoryBot.build(:multiple_holdings) }
  end

  factory :request_with_symphony_errors, class: 'Request' do
    item_id { '123456' }
    location { 'SAL3-STACKS' }
    item_title { 'Title for Request 123456' }

    after(:build) do |request|
      class << request
        def symphony_response_data
          FactoryBot.build(:symphony_scan_with_multiple_items)
        end
      end
    end
  end
end

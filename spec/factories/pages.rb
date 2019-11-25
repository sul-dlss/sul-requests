# frozen_string_literal: true

FactoryBot.define do
  factory :page do
    item_id { '1234' }
    origin { 'GREEN' }
    origin_location { 'STACKS' }
    destination { 'ART' }
    item_title { 'Title for Page 1234' }

    after(:build) do |request|
      class << request
        def symphony_response_data
          FactoryBot.build(:symphony_page_with_single_item)
        end
      end
    end
  end

  factory :page_with_holdings, class: 'Page' do
    item_id { '1234' }
    origin { 'GREEN' }
    origin_location { 'STACKS' }
    destination { 'ART' }

    after(:build) do |page|
      class << page
        def searchworks_item
          @searchworks_item ||= FactoryBot.build(:green_stacks_multi_holdings_searchworks_item, request: self)
        end
      end
    end
  end

  factory :page_with_holdings_summary, class: 'Page' do
    item_id { '1234' }
    origin { 'GREEN' }
    origin_location { 'STACKS' }
    destination { 'ART' }

    after(:build) do |page|
      class << page
        def searchworks_item
          @searchworks_item ||= FactoryBot.build(:mhld_searchworks_item, request: self)
        end
      end
    end
  end
end

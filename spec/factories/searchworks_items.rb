# frozen_string_literal: true

FactoryBot.define do
  factory :green_stacks_searchworks_item, class: 'SearchworksItem' do
    initialize_with { new(request) }

    request { create(:request, origin: 'GREEN', origin_location: 'STACKS') }

    after(:build) do |item|
      class << item
        def json
          FactoryBot.build(:single_holding)
        end
      end
    end
  end

  factory :green_stacks_multi_holdings_searchworks_item, class: 'SearchworksItem' do
    initialize_with { new(request) }

    request { create(:request, origin: 'GREEN', origin_location: 'STACKS') }

    after(:build) do |item|
      class << item
        def json
          FactoryBot.build(:multiple_holdings)
        end
      end
    end
  end

  factory :sal3_stacks_multi_holdings_searchworks_item, class: 'SearchworksItem' do
    initialize_with { new(request) }

    request { create(:request, origin: 'SAL3', origin_location: 'STACKS') }

    after(:build) do |item|
      class << item
        def json
          FactoryBot.build(:sal3_holdings)
        end
      end
    end
  end

  factory :art_multi_holdings_searchworks_item, class: 'SearchworksItem' do
    initialize_with { new(request) }

    request { create(:request, origin: 'ART', origin_location: 'ARTLCKL') }

    after(:build) do |item|
      class << item
        def json
          FactoryBot.build(:searchable_holdings)
        end
      end
    end
  end

  factory :library_instructions_searchworks_item, class: 'SearchworksItem' do
    initialize_with { new(request) }

    request { create(:request, origin: 'ART', origin_location: 'ARTLCKL') }

    after(:build) do |item|
      class << item
        def json
          FactoryBot.build(:library_instructions_holdings)
        end
      end
    end
  end
end

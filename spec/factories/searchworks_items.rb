FactoryGirl.define do
  factory :green_stacks_searchworks_item, class: SearchworksItem do
    initialize_with { new(create(:request, origin: 'GREEN', origin_location: 'STACKS')) }

    after(:build) do |item|
      class << item
        def json
          FactoryGirl.build(:single_holding)
        end
      end
    end
  end

  factory :green_stacks_multi_holdings_searchworks_item, class: SearchworksItem do
    initialize_with { new(create(:request, origin: 'GREEN', origin_location: 'STACKS')) }

    after(:build) do |item|
      class << item
        def json
          FactoryGirl.build(:multiple_holdings)
        end
      end
    end
  end

  factory :sal3_stacks_multi_holdings_searchworks_item, class: SearchworksItem do
    initialize_with { new(create(:request, origin: 'SAL3', origin_location: 'STACKS')) }

    after(:build) do |item|
      class << item
        def json
          FactoryGirl.build(:sal3_holdings)
        end
      end
    end
  end

  factory :spec_coll_stacks_multi_holdings_searchworks_item, class: SearchworksItem do
    initialize_with { new(create(:request, origin: 'SPEC-COLL', origin_location: 'STACKS')) }

    after(:build) do |item|
      class << item
        def json
          FactoryGirl.build(:searchable_holdings)
        end
      end
    end
  end

  factory :mhld_searchworks_item, class: SearchworksItem do
    initialize_with { new(create(:request, origin: 'GREEN', origin_location: 'STACKS')) }

    after(:build) do |item|
      class << item
        def json
          FactoryGirl.build(:mhld_summary_holdings)
        end
      end
    end
  end
end

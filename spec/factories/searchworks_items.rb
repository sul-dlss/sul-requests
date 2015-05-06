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
end

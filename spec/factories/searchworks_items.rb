# frozen_string_literal: true

FactoryBot.define do
  factory :green_stacks_searchworks_item, class: 'SearchworksItem' do
    initialize_with { new(request) }

    request { create(:request, origin: 'GREEN', origin_location: 'STACKS') }

    after(:build) do |item|
      class << item
        # rubocop:disable Metrics/MethodLength
        def json
          {
            holdings: [
              { 'code' => 'GREEN',
                'locations' => [
                  { 'code' => 'STACKS',
                    'items' => [
                      { 'barcode' => '12345678',
                        'callnumber' => 'ABC 123',
                        'type' => 'STKS',
                        'status' => {
                          'availability_class' => 'available',
                          'status_text' => 'Available'
                        } }
                    ] }
                ] }
            ]
          }.stringify_keys
        end
        # rubocop:enable Metrics/MethodLength
      end
    end
  end

  factory :sal_stacks_multi_holdings_searchworks_item, class: 'SearchworksItem' do
    initialize_with { new(request) }

    request { create(:request, origin: 'SAL', origin_location: 'STACKS') }

    after(:build) do |item|
      class << item
        def json
          FactoryBot.build(:sal_holdings)
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
end

FactoryGirl.define do
  factory :multiple_holdings, class: Hash do
    title 'Item Title'

    holdings [
      { 'code' => 'GREEN',
        'locations' => [
          { 'code' => 'STACKS',
            'items' => [
              { 'barcode' => '12345678',
                'callnumber' => 'ABC 123',
                'status' => {
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              },
              { 'barcode' => '87654321',
                'callnumber' => 'ABC 321',
                'status' => {
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              },
              { 'barcode' => '12345679',
                'callnumber' => 'ABC 456',
                'status' => {
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              }
            ]
          }
        ]
      }
    ]

    initialize_with do
      attributes.map do |k, h|
        [k.to_s, h]
      end.to_h
    end
  end

  factory :single_holding, class: Hash do
    title 'Item Title'

    holdings [
      { 'code' => 'GREEN',
        'locations' => [
          { 'code' => 'STACKS',
            'items' => [
              { 'barcode' => '12345678',
                'callnumber' => 'ABC 123',
                'status' => {
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              }
            ]
          }
        ]
      }
    ]

    initialize_with do
      attributes.map do |k, h|
        [k.to_s, h]
      end.to_h
    end
  end

  factory :special_collections_holdings, class: Hash do
    title 'Special Collections Item Title'

    holdings [
      { 'code' => 'SPEC-COLL',
        'locations' => [
          { 'code' => 'STACKS',
            'items' => [
              { 'barcode' => '12345678',
                'callnumber' => 'ABC 123',
                'status' => {
                  'availability_class' => 'page',
                  'status_text' => 'Page'
                }
              },
              { 'barcode' => '87654321',
                'callnumber' => 'ABC 321',
                'status' => {
                  'availability_class' => 'page',
                  'status_text' => 'Page'
                }
              }
            ]
          }
        ]
      }
    ]

    initialize_with do
      attributes.map do |k, h|
        [k.to_s, h]
      end.to_h
    end
  end

  factory :sal3_holdings, class: Hash do
    title 'SAL3 Item Title'

    holdings [
      { 'code' => 'SAL3',
        'locations' => [
          { 'code' => 'STACKS',
            'items' => [
              { 'barcode' => '12345678',
                'callnumber' => 'ABC 123',
                'status' => {
                  'availability_class' => 'page',
                  'status_text' => 'Page'
                }
              },
              { 'barcode' => '87654321',
                'callnumber' => 'ABC 321',
                'status' => {
                  'availability_class' => 'page',
                  'status_text' => 'Page'
                }
              }
            ]
          }
        ]
      }
    ]

    initialize_with do
      attributes.map do |k, h|
        [k.to_s, h]
      end.to_h
    end
  end
end

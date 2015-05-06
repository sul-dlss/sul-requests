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

  factory :searchable_holdings, class: Hash do
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
              { 'barcode' => '23456789',
                'callnumber' => 'ABC 456',
                'status' => {
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              },
              { 'barcode' => '34567890',
                'callnumber' => 'ABC 789',
                'status' => {
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              },
              { 'barcode' => '45678901',
                'callnumber' => 'ABC 012',
                'status' => {
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              },
              { 'barcode' => '56789012',
                'callnumber' => 'ABC 345',
                'status' => {
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              },
              { 'barcode' => '67890123',
                'callnumber' => 'ABC 678',
                'status' => {
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              },
              { 'barcode' => '78901234',
                'callnumber' => 'ABC 901',
                'status' => {
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              },
              { 'barcode' => '89012345',
                'callnumber' => 'ABC 234',
                'status' => {
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              },
              { 'barcode' => '90123456',
                'callnumber' => 'ABC 567',
                'status' => {
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              },
              { 'barcode' => '01234567',
                'callnumber' => 'ABC 890',
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
end

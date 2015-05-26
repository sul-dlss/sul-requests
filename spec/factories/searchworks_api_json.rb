FactoryGirl.define do
  factory :multiple_holdings, class: Hash do
    title 'Item Title'

    format ['Book']

    holdings [
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
                }
              },
              { 'barcode' => '87654321',
                'callnumber' => 'ABC 321',
                'type' => 'STKS',
                'status' => {
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              },
              { 'barcode' => '12345679',
                'callnumber' => 'ABC 456',
                'type' => 'STKS',
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

    format ['Book']

    holdings [
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

    format ['Book']

    holdings [
      { 'code' => 'SPEC-COLL',
        'locations' => [
          { 'code' => 'STACKS',
            'items' => [
              { 'barcode' => '12345678',
                'callnumber' => 'ABC 123',
                'type' => 'STKS',
                'status' => {
                  'availability_class' => 'page',
                  'status_text' => 'Page'
                }
              },
              { 'barcode' => '87654321',
                'callnumber' => 'ABC 321',
                'type' => 'STKS',
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

    format ['Book']

    holdings [
      { 'code' => 'SAL3',
        'locations' => [
          { 'code' => 'STACKS',
            'items' => [
              { 'barcode' => '12345678',
                'callnumber' => 'ABC 123',
                'type' => 'STKS',
                'status' => {
                  'availability_class' => 'page',
                  'status_text' => 'Page'
                }
              },
              { 'barcode' => '87654321',
                'callnumber' => 'ABC 321',
                'type' => 'STKS',
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

  factory :many_holdings, class: Hash do
    title 'Item title'

    format ['Book']

    holdings [
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
                }
              },
              { 'barcode' => '23456789',
                'callnumber' => 'ABC 456',
                'type' => 'SOMETHING-ELSE',
                'status' => {
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              },
              { 'barcode' => '34567890',
                'callnumber' => 'ABC 789',
                'type' => 'STKS-MONO',
                'status' => {
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              },
              { 'barcode' => '45678901',
                'callnumber' => 'ABC 012',
                'type' => 'STKS-PERI',
                'status' => {
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              },
              { 'barcode' => '56789012',
                'callnumber' => 'ABC 345',
                'type' => 'STKS',
                'status' => {
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              },
              { 'barcode' => '67890123',
                'callnumber' => 'ABC 678',
                'type' => 'STKS',
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

  factory :searchable_holdings, class: Hash do
    title 'Item Title'

    format ['Book']

    holdings [
      { 'code' => 'SPEC-COLL',
        'locations' => [
          { 'code' => 'STACKS',
            'items' => [
              { 'barcode' => '12345678',
                'callnumber' => 'ABC 123',
                'type' => 'STKS',
                'current_location' => {
                  'code' => ''
                },
                'home_location' => 'STACKS',
                'status' => {
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              },
              { 'barcode' => '23456789',
                'callnumber' => 'ABC 456',
                'type' => 'STKS',
                'current_location' => {
                  'code' => ''
                },
                'home_location' => 'STACKS',
                'status' => {
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              },
              { 'barcode' => '34567890',
                'callnumber' => 'ABC 789',
                'type' => 'STKS',
                'current_location' => {
                  'code' => ''
                },
                'home_location' => 'STACKS',
                'status' => {
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              },
              { 'barcode' => '45678901',
                'callnumber' => 'ABC 012',
                'type' => 'STKS',
                'current_location' => {
                  'code' => ''
                },
                'home_location' => 'STACKS',
                'status' => {
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              },
              { 'barcode' => '56789012',
                'callnumber' => 'ABC 345',
                'type' => 'STKS',
                'current_location' => {
                  'code' => ''
                },
                'home_location' => 'STACKS',
                'status' => {
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              },
              { 'barcode' => '67890123',
                'callnumber' => 'ABC 678',
                'type' => 'STKS',
                'current_location' => {
                  'code' => ''
                },
                'home_location' => 'STACKS',
                'status' => {
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              },
              { 'barcode' => '78901234',
                'callnumber' => 'ABC 901',
                'type' => 'STKS',
                'current_location' => {
                  'code' => ''
                },
                'home_location' => 'STACKS',
                'status' => {
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              },
              { 'barcode' => '89012345',
                'callnumber' => 'ABC 234',
                'type' => 'STKS',
                'current_location' => {
                  'code' => ''
                },
                'home_location' => 'STACKS',
                'status' => {
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              },
              { 'barcode' => '90123456',
                'callnumber' => 'ABC 567',
                'type' => 'STKS',
                'current_location' => {
                  'code' => ''
                },
                'home_location' => 'STACKS',
                'status' => {
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              },
              { 'barcode' => '01234567',
                'callnumber' => 'ABC 890',
                'type' => 'STKS',
                'current_location' => {
                  'code' => ''
                },
                'home_location' => 'STACKS',
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

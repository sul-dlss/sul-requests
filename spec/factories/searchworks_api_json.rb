FactoryGirl.define do
  factory :multiple_holdings, class: Hash do
    title 'Item Title'

    format ['Book']

    holdings [
      { 'code' => 'GREEN',
        'locations' => [
          { 'code' => 'STACKS',
            'items' => [
              { 'barcode' => '3610512345678',
                'callnumber' => 'ABC 123',
                'type' => 'STKS',
                'status' => {
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              },
              { 'barcode' => '3610587654321',
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

  factory :sal_newark_holding, class: Hash do
    title 'Item Title'

    format ['Book']

    holdings [
      { 'code' => 'SAL-NEWARK',
        'locations' => [
          { 'code' => 'STACKS',
            'mhld' => {},
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

  factory :mhld_summary_holdings, class: Hash do
    title 'Item Title'

    format ['Book']

    holdings [
      { 'code' => 'GREEN',
        'locations' => [
          { 'code' => 'STACKS',
            'mhld' => {
              'library_has' => 'This is the library has holdings summary'
            },
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

  factory :page_mp_holdings, class: Hash do
    title 'PAGE-MP Item Title'

    format ['Book']

    holdings [
      { 'code' => 'SAL3',
        'locations' => [
          { 'code' => 'PAGE-MP',
            'items' => [
              { 'barcode' => '12345678',
                'callnumber' => 'ABC 123',
                'home_location' => 'STACKS',
                'type' => 'STKS',
                'current_location' => {
                  'code' => ''
                },
                'status' => {
                  'availability_class' => 'page',
                  'status_text' => 'Page'
                }
              },
              { 'barcode' => '87654321',
                'callnumber' => 'ABC 321',
                'home_location' => 'STACKS',
                'type' => 'STKS',
                'current_location' => {
                  'code' => ''
                },
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
                'public_note' => 'note for 23456789',
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
                'public_note' => 'note for 45678901',
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

  factory :library_instructions_holdings, class: Hash do
    title 'Item Title'

    format ['Book']

    holdings [
      { 'code' => 'SPEC-COLL',
        'library_instructions' => {
          'heading' => 'Instruction Heading',
          'text' => 'This is the library instruction'
        },
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

  factory :checkedout_holdings, class: Hash do
    title 'Checked out item'

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
                  'availability_class' => 'available',
                  'status_text' => 'Available'
                }
              },
              { 'barcode' => '87654321',
                'callnumber' => 'ABC 321',
                'current_location' => {
                  'code' => 'CHECKEDOUT'
                },
                'due_date' => '01/01/2015',
                'type' => 'STKS',
                'status' => {
                  'availability_class' => 'page',
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

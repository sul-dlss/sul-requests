# frozen_string_literal: true

if Settings.ils.bib_model == 'SearchworksItem'
  FactoryBot.define do
    factory :searchworks_item, class: 'SearchworksItem' do
      initialize_with do
        SearchworksItem.new(attributes.stringify_keys, '1234')
      end
    end

    factory :multiple_holdings, parent: :searchworks_item do
      title { 'Item Title' }

      format { ['Book'] }

      holdings do
        [
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
                    } },
                  { 'barcode' => '3610587654321',
                    'callnumber' => 'ABC 321',
                    'type' => 'STKS',
                    'status' => {
                      'availability_class' => 'available',
                      'status_text' => 'Available'
                    } },
                  { 'barcode' => '12345679',
                    'callnumber' => 'ABC 456',
                    'type' => 'STKS',
                    'status' => {
                      'availability_class' => 'available',
                      'status_text' => 'Available'
                    } }
                ] }
            ] }
        ]
      end
    end

    factory :single_holding, parent: :searchworks_item do
      title { 'Item Title' }

      format { ['Book'] }

      holdings do
        [
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
      end
    end

    factory :scannable_only_holdings, parent: :searchworks_item do
      title { 'Item Title' }

      format { ['Book'] }

      holdings do
        [
          { 'code' => 'SAL',
            'locations' => [
              { 'code' => 'SAL-TEMP',
                'items' => [
                  { 'barcode' => '12345678',
                    'callnumber' => 'ABC 123',
                    'type' => 'NONCIRC' }
                ] }
            ] }
        ]
      end
    end

    factory :special_collections_holdings, parent: :searchworks_item do
      title { 'Special Collections Item Title' }
      author { 'John Q. Public' }
      pub_date { '2018' }

      format { ['Book'] }

      holdings do
        [
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
                    } },
                  { 'barcode' => '87654321',
                    'callnumber' => 'ABC 321',
                    'type' => 'STKS',
                    'status' => {
                      'availability_class' => 'page',
                      'status_text' => 'Page'
                    } }
                ] }
            ] }
        ]
      end
    end

    factory :special_collections_single_holding, parent: :searchworks_item do
      title { 'Special Collections Item Title' }
      author { 'John Q. Public' }
      pub_date { '2018' }

      format { ['Book'] }

      holdings do
        [
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
                    } }
                ] }
            ] }
        ]
      end
    end

    factory :special_collections_finding_aid_holdings, parent: :searchworks_item do
      title { 'Special Collections Item Title' }
      author { 'John Q. Public' }
      pub_date { '2018' }
      finding_aid { 'http://www.oac.cdlib.org/findaid/ark:/12345/abcdefgh/' }

      format { ['Book'] }

      holdings do
        [
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
                    } },
                  { 'barcode' => '87654321',
                    'callnumber' => 'ABC 321',
                    'type' => 'STKS',
                    'status' => {
                      'availability_class' => 'page',
                      'status_text' => 'Page'
                    } }
                ] }
            ] }
        ]
      end
    end

    factory :sal3_holding, parent: :searchworks_item do
      title { 'SAL3 Item Title' }

      format { ['Book'] }

      holdings do
        [
          { 'code' => 'SAL3',
            'locations' => [
              { 'code' => 'STACKS',
                'items' => [
                  { 'barcode' => '87654321',
                    'callnumber' => 'ABC 321',
                    'type' => 'STKS',
                    'status' => {
                      'availability_class' => 'page',
                      'status_text' => 'Page'
                    } }
                ] }
            ] }
        ]
      end
    end

    factory :sal3_holdings, parent: :searchworks_item do
      title { 'SAL3 Item Title' }

      format { ['Book'] }

      holdings do
        [
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
                    } },
                  { 'barcode' => '87654321',
                    'callnumber' => 'ABC 321',
                    'type' => 'STKS',
                    'status' => {
                      'availability_class' => 'page',
                      'status_text' => 'Page'
                    } }
                ] }
            ] }
        ]
      end
    end

    factory :sal_holdings, parent: :searchworks_item do
      title { 'SAL Item Title' }

      format { ['Book'] }

      holdings do
        [
          { 'code' => 'SAL',
            'locations' => [
              { 'code' => 'STACKS',
                'items' => [
                  { 'barcode' => '12345678',
                    'callnumber' => 'ABC 123',
                    'type' => 'STKS',
                    'status' => {
                      'availability_class' => 'page',
                      'status_text' => 'Page'
                    } },
                  { 'barcode' => '87654321',
                    'callnumber' => 'ABC 321',
                    'type' => 'STKS',
                    'status' => {
                      'availability_class' => 'page',
                      'status_text' => 'Page'
                    } }
                ] }
            ] }
        ]
      end
    end

    factory :page_mp_holdings, parent: :searchworks_item do
      title { 'PAGE-MP Item Title' }

      format { ['Book'] }

      holdings do
        [
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
                    } },
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
                    } }
                ] }
            ] }
        ]
      end
    end

    factory :many_holdings, parent: :searchworks_item do
      title { 'Item title' }

      format { ['Book'] }

      holdings do
        [
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
                    } },
                  { 'barcode' => '23456789',
                    'callnumber' => 'ABC 456',
                    'type' => 'SOMETHING-ELSE',
                    'status' => {
                      'availability_class' => 'available',
                      'status_text' => 'Available'
                    } },
                  { 'barcode' => '34567890',
                    'callnumber' => 'ABC 789',
                    'type' => 'STKS-MONO',
                    'status' => {
                      'availability_class' => 'available',
                      'status_text' => 'Available'
                    } },
                  { 'barcode' => '45678901',
                    'callnumber' => 'ABC 012',
                    'type' => 'STKS-PERI',
                    'status' => {
                      'availability_class' => 'available',
                      'status_text' => 'Available'
                    } },
                  { 'barcode' => '56789012',
                    'callnumber' => 'ABC 345',
                    'type' => 'STKS',
                    'status' => {
                      'availability_class' => 'available',
                      'status_text' => 'Available'
                    } },
                  { 'barcode' => '67890123',
                    'callnumber' => 'ABC 678',
                    'type' => 'STKS',
                    'status' => {
                      'availability_class' => 'available',
                      'status_text' => 'Available'
                    } }
                ] }
            ] }
        ]
      end
    end

    factory :searchable_holdings, parent: :searchworks_item do
      title { 'Item Title' }

      format { ['Book'] }

      holdings do
        [
          { 'code' => 'ART',
            'locations' => [
              { 'code' => 'ARTLCKL',
                'items' => [
                  { 'barcode' => '12345678',
                    'callnumber' => 'ABC 123',
                    'type' => 'LCKSTK',
                    'current_location' => {
                      'code' => ''
                    },
                    'home_location' => 'STACKS',
                    'status' => {
                      'availability_class' => 'available',
                      'status_text' => 'Available'
                    } },
                  { 'barcode' => '23456789',
                    'callnumber' => 'ABC 456',
                    'type' => 'LCKSTK',
                    'public_note' => 'note for 23456789',
                    'current_location' => {
                      'code' => ''
                    },
                    'home_location' => 'STACKS',
                    'status' => {
                      'availability_class' => 'available',
                      'status_text' => 'Available'
                    } },
                  { 'barcode' => '34567890',
                    'callnumber' => 'ABC 789',
                    'type' => 'LCKSTK',
                    'current_location' => {
                      'code' => 'THE-CURRENT-LOCATION'
                    },
                    'home_location' => 'STACKS',
                    'status' => {
                      'availability_class' => 'available',
                      'status_text' => 'Available'
                    } },
                  { 'barcode' => '45678901',
                    'callnumber' => 'ABC 012',
                    'type' => 'LCKSTK',
                    'public_note' => 'note for 45678901',
                    'current_location' => {
                      'code' => ''
                    },
                    'home_location' => 'STACKS',
                    'status' => {
                      'availability_class' => 'available',
                      'status_text' => 'Available'
                    } },
                  { 'barcode' => '56789012',
                    'callnumber' => 'ABC 345',
                    'type' => 'LCKSTK',
                    'current_location' => {
                      'code' => ''
                    },
                    'home_location' => 'STACKS',
                    'status' => {
                      'availability_class' => 'available',
                      'status_text' => 'Available'
                    } },
                  { 'barcode' => '67890123',
                    'callnumber' => 'ABC 678',
                    'type' => 'LCKSTK',
                    'current_location' => {
                      'code' => ''
                    },
                    'home_location' => 'STACKS',
                    'status' => {
                      'availability_class' => 'available',
                      'status_text' => 'Available'
                    } },
                  { 'barcode' => '78901234',
                    'callnumber' => 'ABC 901',
                    'type' => 'LCKSTK',
                    'current_location' => {
                      'code' => ''
                    },
                    'home_location' => 'STACKS',
                    'status' => {
                      'availability_class' => 'available',
                      'status_text' => 'Available'
                    } },
                  { 'barcode' => '89012345',
                    'callnumber' => 'ABC 234',
                    'type' => 'LCKSTK',
                    'current_location' => {
                      'code' => ''
                    },
                    'home_location' => 'STACKS',
                    'status' => {
                      'availability_class' => 'available',
                      'status_text' => 'Available'
                    } },
                  { 'barcode' => '90123456',
                    'callnumber' => 'ABC 567',
                    'type' => 'LCKSTK',
                    'current_location' => {
                      'code' => ''
                    },
                    'home_location' => 'STACKS',
                    'status' => {
                      'availability_class' => 'available',
                      'status_text' => 'Available'
                    } },
                  { 'barcode' => '01234567',
                    'callnumber' => 'ABC 890',
                    'type' => 'LCKSTK',
                    'current_location' => {
                      'code' => ''
                    },
                    'home_location' => 'STACKS',
                    'status' => {
                      'availability_class' => 'available',
                      'status_text' => 'Available'
                    } }
                ] }
            ] }
        ]
      end
    end

    factory :searchable_spec_holdings, parent: :searchworks_item do
      title { 'Item Title' }

      format { ['Book'] }

      holdings do
        [
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
                    } },
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
                    } },
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
                    } },
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
                    } },
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
                    } },
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
                    } },
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
                    } },
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
                    } },
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
                    } },
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
                    } }
                ] }
            ] }
        ]
      end
    end

    factory :library_instructions_holdings, parent: :searchworks_item do
      title { 'Item Title' }

      format { ['Book'] }

      holdings do
        [
          { 'code' => 'EDUCATION',
            'library_instructions' => {
              'heading' => 'Instruction Heading',
              'text' => 'This is the library instruction'
            },
            'locations' => [
              { 'code' => 'STACKS',
                'items' => [
                  { 'barcode' => '12345678',
                    'callnumber' => 'ABC 123',
                    'type' => 'STKS-MONO',
                    'current_location' => {
                      'code' => 'CHECKEDOUT'
                    },
                    'status' => {
                      'availability_class' => 'unknown',
                      'status_text' => 'Unknown'
                    } }
                ] }
            ] }
        ]
      end
    end

    factory :checkedout_holdings, parent: :searchworks_item do
      title { 'Checked out item' }

      format { ['Book'] }

      holdings do
        [
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
                    } },
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
                    } }
                ] }
            ] }
        ]
      end
    end

    factory :green_stacks_searchworks_item, parent: :searchworks_item do
      holdings do
        [
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
      end
    end
  end
end

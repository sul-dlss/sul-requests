# frozen_string_literal: true

FactoryBot.define do
  factory :multiple_holdings, class: 'Hash' do
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
    end

    initialize_with do
      attributes.transform_keys(&:to_s).to_h
    end
  end

  factory :single_holding, class: 'Hash' do
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
                  }
                }
              ]
            }
          ]
        }
      ]
    end

    initialize_with do
      attributes.transform_keys(&:to_s).to_h
    end
  end

  factory :scannable_only_holdings, class: 'Hash' do
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
                  'type' => 'NONCIRC'
                }
              ]
            }
          ]
        }
      ]
    end

    initialize_with do
      attributes.transform_keys(&:to_s).to_h
    end
  end

  factory :sal_newark_holding, class: 'Hash' do
    title { 'Item Title' }

    format { ['Book'] }

    holdings do
      [
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
    end

    initialize_with do
      attributes.transform_keys(&:to_s).to_h
    end
  end

  factory :special_collections_holdings, class: 'Hash' do
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
    end

    initialize_with do
      attributes.transform_keys(&:to_s).to_h
    end
  end

  factory :special_collections_single_holding, class: 'Hash' do
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
                  }
                }
              ]
            }
          ]
        }
      ]
    end

    initialize_with do
      attributes.transform_keys(&:to_s).to_h
    end
  end

  factory :special_collections_finding_aid_holdings, class: 'Hash' do
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
    end

    initialize_with do
      attributes.transform_keys(&:to_s).to_h
    end
  end

  factory :sal3_holdings, class: 'Hash' do
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
    end

    initialize_with do
      attributes.transform_keys(&:to_s).to_h
    end
  end

  factory :page_mp_holdings, class: 'Hash' do
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
    end

    initialize_with do
      attributes.transform_keys(&:to_s).to_h
    end
  end

  factory :many_holdings, class: 'Hash' do
    title { 'Item title' }

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
    end

    initialize_with do
      attributes.transform_keys(&:to_s).to_h
    end
  end

  factory :searchable_holdings, class: 'Hash' do
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
                  }
                },
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
                  }
                },
                { 'barcode' => '34567890',
                  'callnumber' => 'ABC 789',
                  'type' => 'LCKSTK',
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
                  'type' => 'LCKSTK',
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
                  'type' => 'LCKSTK',
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
                  'type' => 'LCKSTK',
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
                  'type' => 'LCKSTK',
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
                  'type' => 'LCKSTK',
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
                  'type' => 'LCKSTK',
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
                  'type' => 'LCKSTK',
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
    end

    initialize_with do
      attributes.transform_keys(&:to_s).to_h
    end
  end

  factory :searchable_spec_holdings, class: 'Hash' do
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
    end

    initialize_with do
      attributes.transform_keys(&:to_s).to_h
    end
  end

  factory :library_instructions_holdings, class: 'Hash' do
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
                  }
                }
              ]
            }
          ]
        }
      ]
    end

    initialize_with do
      attributes.transform_keys(&:to_s).to_h
    end
  end

  factory :checkedout_holdings, class: 'Hash' do
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
    end

    initialize_with do
      attributes.transform_keys(&:to_s).to_h
    end
  end
end

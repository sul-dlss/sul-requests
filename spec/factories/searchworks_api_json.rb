# frozen_string_literal: true

FactoryBot.define do
  factory :location, class: 'Folio::Location' do
    id { 'uuid' }
    code { 'GRE-STACKS' }
    name { 'Location name' }
    discovery_display_name { 'Discovery display name' }
    campus { Folio::Campus.new(id: 'uuid') }
    library { Folio::Library.new(id: 'uuid') }
    institution { Folio::Institution.new(id: 'uuid') }
    details { {} }

    initialize_with { new(**attributes) }
  end

  factory :pageable_location, parent: :location do
    id { '1146c4fa-5798-40e1-9b8e-92ee4c9f2ee2' }
    library { Folio::Library.new(id: 'ddd3bce1-9f8f-4448-8d6d-b6c1b3907ba9') }
    code { 'SAL3-STACKS' }
  end

  factory :aeon_mediated_location, parent: :location do
    details { { 'pageMediationGroupKey' => 'SPEC-COLL', 'pageAeonSite' => 'UA' } }
  end

  factory :art_mediated_location, parent: :location do
    details { { 'pageMediationGroupKey' => 'ART' } }
  end

  factory :material_type_book, class: 'Folio::MaterialType' do
    id { Folio::Types.get_type('material_types').find { |t| t['name'] == 'book'}.dig('id') }

    initialize_with { new(**attributes) }
  end

  factory :multiple_holdings, class: 'Folio::Instance' do
    id { '1234' }
    hrid { 'a1234' }
    title { 'Item Title' }
    format { 'Book' }
    items do
      [
        Folio::Item.new(
          barcode: '3610512345678',
          callnumber: 'ABC 123',
          status: 'Available',
          effective_location: build(:location, code: 'GRE-STACKS'),
          public_note: '',
          type: 'STKS'
        ),
        Folio::Item.new(
          barcode: '3610587654321',
          callnumber: 'ABC 321',
          status: 'Available',
          effective_location: build(:location, code: 'GRE-STACKS'),
          public_note: '',
          type: 'STKS'
        ),
        Folio::Item.new(
          barcode: '12345679',
          callnumber: 'ABC 456',
          status: 'Available',
          effective_location: build(:location, code: 'GRE-STACKS'),
          public_note: '',
          type: 'STKS'
        )
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :sal3_holding, class: 'Folio::Instance' do
    id { '12345' }
    hrid { 'a12345' }
    title { 'Item Title' }
    format { 'Book' }
    items do
      [
        Folio::Item.new(
          barcode: '87654321',
          callnumber: 'ABC 87654321',
          status: 'Available',
          effective_location: build(:pageable_location),
          material_type: build(:material_type_book),
          public_note: '',
          type: 'STKS'
        )
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :single_holding, class: 'Folio::Instance' do
    id { '123' }

    title { 'Item Title' }

    format { ['Book'] }

    items do
      [
        Folio::Item.new(
          barcode: '12345678',
          callnumber: 'ABC 123',
          status: 'Available',
          effective_location: build(:location, code: 'GRE-STACKS'),
          public_note: '',
          type: 'STKS'
        )
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :scannable_only_holdings, class: 'Folio::Instance' do
    id { '1234' }
    title { 'Item Title' }

    format { ['Book'] }

    items do
      [
        Folio::Item.new(
          barcode: '12345678',
          callnumber: 'ABC 123',
          status: 'Available',
          effective_location: build(:location, code: 'SAL-TEMP'),
          public_note: '',
          type: 'NONCIRC'
        )
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :special_collections_holdings, class: 'Folio::Instance' do
    id { '1234' }
    hrid { 'a1234' }
    title { 'Special Collections Item Title' }
    contributors { [{ 'primary' => true, 'name' => 'John Q. Public' }] }
    pub_date { '2018' }

    format { ['Book'] }

    items do
      [
        Folio::Item.new(
          barcode: '12345678',
          callnumber: 'ABC 123',
          status: 'Page',
          effective_location: build(:aeon_mediated_location, code: 'SPEC-STACKS'),
          public_note: '',
          type: 'STKS'
        ),
        Folio::Item.new(
          barcode: '87654321',
          callnumber: 'ABC 321',
          status: 'Page',
          effective_location: build(:aeon_mediated_location, code: 'SPEC-STACKS'),
          public_note: '',
          type: 'STKS'
        )
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :special_collections_single_holding, class: 'Folio::Instance' do
    id { '1234' }
    hrid { 'a1234' }
    title { 'Special Collections Item Title' }
    contributors { [{ 'primary' => true, 'name' => 'John Q. Public' }] }
    pub_date { '2018' }

    format { ['Book'] }

    items do
      [
        Folio::Item.new(
          barcode: '12345678',
          callnumber: 'ABC 123',
          status: 'Page',
          effective_location: build(:aeon_mediated_location, code: 'SPEC-STACKS'),
          public_note: '',
          type: 'STKS'
        )
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :special_collections_finding_aid_holdings, class: 'Folio::Instance' do
    id { '1234' }
    hrid { 'a1234' }
    title { 'Special Collections Item Title' }
    pub_date { '2018' }
    contributors { [{ 'primary' => true, 'name' => 'John Q. Public' }] }
    electronic_access { [{ 'uri' => 'http://www.oac.cdlib.org/findaid/ark:/12345/abcdefgh/', 'materialsSpecification' => 'Finding aid available online' }] }

    format { ['Book'] }

    items do
      [
        Folio::Item.new(
          barcode: '12345678',
          callnumber: 'ABC 123',
          status: 'Page',
          effective_location: build(:aeon_mediated_location, code: 'SPEC-STACKS'),
          public_note: '',
          type: 'STKS'
        )
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :sal3_holdings, class: 'Folio::Instance' do
    id { '123456' }
    title { 'SAL3 Item Title' }

    format { ['Book'] }

    items do
      [
        Folio::Item.new(
          barcode: '12345678',
          callnumber: 'ABC 123',
          status: 'Page',
          effective_location: build(:location, code: 'SAL3-STACKS'),
          public_note: '',
          type: 'STKS'
        ),
        Folio::Item.new(
          barcode: '87654321',
          callnumber: 'ABC 321',
          status: 'Page',
          effective_location: build(:location, code: 'SAL3-STACKS'),
          public_note: '',
          type: 'STKS'
        )
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :sal_holdings, class: 'Folio::Instance' do
    id { '1234' }
    title { 'SAL Item Title' }

    format { ['Book'] }

    items do
      [
        Folio::Item.new(
          barcode: '12345678',
          callnumber: 'ABC 123',
          status: 'Page',
          effective_location: build(:location, code: 'SAL-STACKS'),
          public_note: '',
          type: 'STKS'
        ),
        Folio::Item.new(
          barcode: '87654321',
          callnumber: 'ABC 321',
          status: 'Page',
          effective_location: build(:location, code: 'SAL-STACKS'),
          public_note: '',
          type: 'STKS'
        )
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :page_mp_holdings, class: 'Folio::Instance' do
    id { '1234' }
    title { 'PAGE-MP Item Title' }

    format { ['Book'] }

    items do
      [
        Folio::Item.new(
          barcode: '12345678',
          callnumber: 'ABC 123',
          status: 'Page',
          effective_location: build(:location, code: 'SAL3-PAGE-MP'),
          public_note: '',
          type: 'STKS'
        ),
        Folio::Item.new(
          barcode: '87654321',
          callnumber: 'ABC 321',
          status: 'Page',
          effective_location: build(:location, code: 'SAL3-PAGE-MP'),
          public_note: '',
          type: 'STKS'
        )
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :many_holdings, class: 'Folio::Instance' do
    id { '1234' }
    title { 'Item title' }

    format { ['Book'] }

    items do
      [
        Folio::Item.new(
          barcode: '12345678',
          callnumber: 'ABC 123',
          status: 'Available',
          effective_location: build(:location, code: 'SAL3-STACKS'),
          public_note: '',
          type: 'STKS'
        ),
        Folio::Item.new(
          barcode: '23456789',
          callnumber: 'ABC 456',
          status: 'Available',
          effective_location: build(:location, code: 'SAL3-STACKS'),
          public_note: '',
          type: 'STKS'
        ),
        Folio::Item.new(
          barcode: '34567890',
          callnumber: 'ABC 789',
          status: 'Available',
          effective_location: build(:location, code: 'SAL3-STACKS'),
          public_note: '',
          type: 'STKS'
        ),
        Folio::Item.new(
          barcode: '45678901',
          callnumber: 'ABC 012',
          status: 'Available',
          effective_location: build(:location, code: 'SAL3-STACKS'),
          public_note: 'note for 45678901',
          type: 'STKS'
        ),
        Folio::Item.new(
          barcode: '56789012',
          callnumber: 'ABC 345',
          status: 'Available',
          effective_location: build(:location, code: 'SAL3-STACKS'),
          public_note: '',
          type: 'STKS'
        ),
        Folio::Item.new(
          barcode: '67890123',
          callnumber: 'ABC 678',
          status: 'Available',
          effective_location: build(:location, code: 'SAL3-STACKS'),
          public_note: '',
          type: 'STKS'
        )
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :searchable_holdings, class: 'Folio::Instance' do
    id { '1234' }
    title { 'Item Title' }

    format { ['Book'] }

    items do
      [
        Folio::Item.new(
          barcode: '12345678',
          callnumber: 'ABC 123',
          status: 'Available',
          effective_location: build(:location, code: 'ART-LOCKED-LARGE'),
          public_note: '',
          type: 'LCKSTK'
        ),
        Folio::Item.new(
          barcode: '23456789',
          callnumber: 'ABC 456',
          status: 'Available',
          effective_location: build(:location, code: 'ART-LOCKED-LARGE'),
          public_note: 'note for 23456789',
          type: 'LCKSTK'
        ),
        Folio::Item.new(
          barcode: '34567890',
          callnumber: 'ABC 789',
          status: 'THE-CURRENT-LOCATION',
          effective_location: build(:location, code: 'ART-LOCKED-LARGE'),
          public_note: '',
          type: 'LCKSTK'
        ),
        Folio::Item.new(
          barcode: '45678901',
          callnumber: 'ABC 012',
          status: 'Available',
          effective_location: build(:location, code: 'ART-LOCKED-LARGE'),
          public_note: 'note for 45678901',
          type: 'LCKSTK'
        ),
        Folio::Item.new(
          barcode: '56789012',
          callnumber: 'ABC 345',
          status: 'Available',
          effective_location: build(:location, code: 'ART-LOCKED-LARGE'),
          public_note: '',
          type: 'LCKSTK'
        ),
        Folio::Item.new(
          barcode: '67890123',
          callnumber: 'ABC 678',
          status: 'Available',
          effective_location: build(:location, code: 'ART-LOCKED-LARGE'),
          public_note: '',
          type: 'LCKSTK'
        ),
        Folio::Item.new(
          barcode: '78901234',
          callnumber: 'ABC 901',
          status: 'Available',
          effective_location: build(:location, code: 'ART-LOCKED-LARGE'),
          public_note: '',
          type: 'LCKSTK'
        ),
        Folio::Item.new(
          barcode: '89012345',
          callnumber: 'ABC 234',
          status: 'Available',
          effective_location: build(:location, code: 'ART-LOCKED-LARGE'),
          public_note: '',
          type: 'LCKSTK'
        ),
        Folio::Item.new(
          barcode: '90123456',
          callnumber: 'ABC 567',
          status: 'Available',
          effective_location: build(:location, code: 'ART-LOCKED-LARGE'),
          public_note: '',
          type: 'LCKSTK'
        ),
        Folio::Item.new(
          barcode: '01234567',
          callnumber: 'ABC 890',
          status: 'Available',
          effective_location: build(:location, code: 'ART-LOCKED-LARGE'),
          public_note: '',
          type: 'LCKSTK'
        )
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :searchable_spec_holdings, class: 'Folio::Instance' do
    id { '1234' }
    title { 'Item Title' }

    format { ['Book'] }

    items do
      [
        Folio::Item.new(
          barcode: '12345678',
          callnumber: 'ABC 123',
          status: 'Available',
          effective_location: build(:location, code: 'SPEC-STACKS'),
          public_note: '',
          type: 'STKS'
        ),
        Folio::Item.new(
          barcode: '23456789',
          callnumber: 'ABC 456',
          status: 'Available',
          effective_location: build(:location, code: 'SPEC-STACKS'),
          public_note: '',
          type: 'STKS'
        ),
        Folio::Item.new(
          barcode: '34567890',
          callnumber: 'ABC 789',
          status: 'Available',
          effective_location: build(:location, code: 'SPEC-STACKS'),
          public_note: '',
          type: 'STKS'
        ),
        Folio::Item.new(
          barcode: '45678901',
          callnumber: 'ABC 012',
          status: 'Available',
          effective_location: build(:location, code: 'SPEC-STACKS'),
          public_note: 'note for 45678901',
          type: 'STKS'
        ),
        Folio::Item.new(
          barcode: '56789012',
          callnumber: 'ABC 345',
          status: 'Available',
          effective_location: build(:location, code: 'SPEC-STACKS'),
          public_note: '',
          type: 'STKS'
        ),
        Folio::Item.new(
          barcode: '67890123',
          callnumber: 'ABC 678',
          status: 'Available',
          effective_location: build(:location, code: 'SPEC-STACKS'),
          public_note: '',
          type: 'STKS'
        ),
        Folio::Item.new(
          barcode: '78901234',
          callnumber: 'ABC 901',
          status: 'Available',
          effective_location: build(:location, code: 'SPEC-STACKS'),
          public_note: '',
          type: 'STKS'
        ),
        Folio::Item.new(
          barcode: '89012345',
          callnumber: 'ABC 234',
          status: 'Available',
          effective_location: build(:location, code: 'SPEC-STACKS'),
          public_note: '',
          type: 'STKS'
        ),
        Folio::Item.new(
          barcode: '90123456',
          callnumber: 'ABC 567',
          status: 'Available',
          effective_location: build(:location, code: 'SPEC-STACKS'),
          public_note: '',
          type: 'STKS'
        ),
        Folio::Item.new(
          barcode: '01234567',
          callnumber: 'ABC 890',
          status: 'Available',
          effective_location: build(:location, code: 'SPEC-STACKS'),
          public_note: '',
          type: 'STKS'
        )
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :checkedout_holdings, class: 'Folio::Instance' do
    id { '1234' }
    title { 'Checked out item' }

    format { ['Book'] }

    items do
      [
        Folio::Item.new(
          barcode: '12345678',
          callnumber: 'ABC 123',
          status: 'Available',
          effective_location: build(:location, code: 'SAL3-STACKS'),
          public_note: '',
          type: 'STKS'
        ),
        Folio::Item.new(
          barcode: '87654321',
          callnumber: 'ABC 321',
          due_date: '2015-01-01T12:59:00.000+00:00',
          status: 'Checked out',
          effective_location: build(:location, code: 'SAL3-STACKS'),
          public_note: '',
          type: 'STKS'
        )
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end
end

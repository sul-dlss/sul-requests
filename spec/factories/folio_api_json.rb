# frozen_string_literal: true

FactoryBot.define do
  factory :location, class: 'Folio::Location' do
    id { Folio::Types.locations.find_by(code:).id }
    code { 'SAL3-STACKS' }
    name { 'Location name' }
    discovery_display_name { 'Discovery display name' }
    campus { Folio::Campus.new(id: 'uuid', code: 'SUL') }
    campus_id { 'uuid' }
    library { Folio::Library.new(id: 'uuid', code: 'LIB') }
    library_id { 'uuid' }
    primary_service_point_id { nil }
    institution { Folio::Institution.new(id: 'uuid') }
    details { {} }

    initialize_with { new(**attributes) }
  end

  factory :mediated_location, parent: :location do
    details { { 'pageMediationGroupKey' => 'ART', 'pageServicePoints' => [{ 'code' => 'ART' }] } }
  end

  factory :page_mp_location, parent: :location do
    code { 'SAL3-PAGE-MP' }
    details { { 'pageMediationGroupKey' => 'PAGE-MP', 'pageServicePoints' => [{ 'code' => 'EARTH-SCI' }] } }
  end

  factory :page_lp_location, parent: :location do
    code { 'SAL3-PAGE-LP' }
    details { { 'pageServicePoints' => [{ 'code' => 'MUSIC' }, { 'code' => 'MEDIA-CENTER' }] } }
  end

  factory :page_en_location, parent: :location do
    code { 'SAL3-PAGE-EN' }
    details { { 'pageServicePoints' => [{ 'code' => 'ENG' }] } }
  end

  factory :page_as_location, parent: :location do
    code { 'SAL3-PAGE-AS' }
    details { { 'pageAeonSite' => 'ARS' } }
  end

  factory :scannable_location, parent: :location do
    code { 'SAL3-STACKS' }
    details { { 'scanServicePointCode' => 'SAL3' } }
  end

  factory :sal_temp_location, parent: :location do
    code { 'SAL-TEMP' }
    details { { 'scanServicePointCode' => 'GREEN' } }
  end

  factory :mmstacks_location, parent: :location do
    code { 'MEDIA-CAGE' }
    library { Folio::Library.new(id: '0acfabb7-0a71-47be-82c0-c0200dd47952', code: 'MEDIA-CENTER') }
  end

  factory :law_location, parent: :location do
    code { 'LAW-STACKS1' }
    library { Folio::Library.new(id: '0acfabb7-0a71-47be-82c0-c0200dd47952', code: 'LAW') }
    campus { Folio::Library.new(id: '0acfabb7-0a71-47be-82c0-c0200dd47952', code: 'LAW') }
  end

  factory :eal_sets_location, parent: :location do
    code { 'EAL-SETS' }
    library { Folio::Library.new(id: '0acfabb7-0a71-47be-82c0-c0200dd47952', code: 'EAST-ASIA') }
  end

  factory :green_location, parent: :location do
    code { 'GRE-STACKS' }
    library { Folio::Library.new(id: 'f6b5519e-88d9-413e-924d-9ed96255f72e', code: 'GREEN') }
  end

  factory :spec_coll_location, parent: :location do
    code { 'SPEC-STACKS' }
    details { { 'pageAeonSite' => 'SPECUA' } }
  end

  factory :book_material_type, class: 'Folio::MaterialType' do
    id { '1a54b431-2e4f-452d-9cae-9cee66c9a892' }
    name { 'book' }

    initialize_with { new(**attributes) }
  end

  factory :multimedia_material_type, class: 'Folio::MaterialType' do
    id { '794de86f-ecbc-45ad-b790-f30eb19797ec' }
    name { 'multimedia' }

    initialize_with { new(**attributes) }
  end

  factory :item, class: 'Folio::Item' do
    id { '0ce74882-9e05-57e7-9a4e-d81821e06874' }
    barcode { '3610512345678' }
    callnumber { 'ABC 123' }
    status { 'Available' }
    public_note { '' }
    type { '' }
    material_type { build(:book_material_type) }
    loan_type { Folio::LoanType.new(id: '') }
    effective_location { build(:location, code: 'GRE-STACKS') }
    initialize_with { new(**attributes) }
  end

  factory :multiple_holdings, class: 'Folio::Instance' do
    id { '1234' }
    hrid { 'a1234' }
    title { 'Item Title' }
    format { 'Book' }
    items do
      [
        build(:item,
              barcode: '3610512345678',
              callnumber: 'ABC 123',
              effective_location: build(:location, code: 'SAL3-STACKS')),
        build(:item,
              barcode: '3610587654321',
              callnumber: 'ABC 321',
              effective_location: build(:location, code: 'SAL3-STACKS')),
        build(:item,
              barcode: '12345679',
              callnumber: 'ABC 456',
              effective_location: build(:location, code: 'SAL3-STACKS'))
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
        build(:item,
              barcode: '87654321',
              callnumber: 'ABC 87654321',
              effective_location: build(:location, code: 'SAL3-STACKS'))
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :sal3_as_holding, class: 'Folio::Instance' do
    id { '12345' }
    hrid { 'a12345' }
    title { 'Item Title' }
    format { 'Book' }
    items do
      [
        build(:item,
              barcode: '87654321',
              callnumber: 'ABC 87654321',
              effective_location: build(:page_as_location))
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
        build(:item,
              barcode: '12345678',
              callnumber: 'ABC 123',
              effective_location: build(:location, code: 'SAL3-STACKS'))
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :mmstacks_holding, class: 'Folio::Instance' do
    id { '123' }

    title { 'Item Title' }

    format { ['Book'] }

    items do
      [
        build(:item,
              barcode: '12345678',
              callnumber: 'ABC 123',
              effective_location: build(:mmstacks_location))
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :single_law_holding, class: 'Folio::Instance' do
    id { '123' }

    title { 'Item Title' }

    format { ['Book'] }

    items do
      [
        build(:item,
              barcode: '12345678',
              callnumber: 'ABC 123',
              effective_location: build(:law_location))
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
        build(:item,
              barcode: '12345678',
              callnumber: 'ABC 123',
              effective_location: build(:sal_temp_location),
              type: 'NONCIRC')
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
        build(:item,
              barcode: '12345678',
              callnumber: 'ABC 123',
              status: 'Available',
              effective_location: build(:spec_coll_location)),
        build(:item,
              barcode: '87654321',
              callnumber: 'ABC 321',
              status: 'Available',
              effective_location: build(:spec_coll_location))
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
        build(:item,
              barcode: '12345678',
              callnumber: 'ABC 123',
              status: 'Available',
              effective_location: build(:spec_coll_location))
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
    electronic_access { [{ 'uri' => 'http://www.oac.cdlib.org/findaid/ark:/13030/tf109n9832/', 'materialsSpecification' => 'Finding aid available online' }] }

    format { ['Book'] }

    items do
      [
        build(:item,
              barcode: '12345678',
              callnumber: 'ABC 123',
              status: 'Available',
              effective_location: build(:spec_coll_location))
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
        build(:item,
              barcode: '12345678',
              callnumber: 'ABC 123',
              status: 'Available',
              effective_location: build(:location, code: 'SAL3-STACKS')),
        build(:item,
              barcode: '87654321',
              callnumber: 'ABC 321',
              status: 'Available',
              effective_location: build(:location, code: 'SAL3-STACKS'))
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :scannable_holdings, class: 'Folio::Instance' do
    id { '1234' }
    title { 'SAL Item Title' }
    contributors { [{ 'primary' => true, 'name' => 'John Q. Public' }] }

    format { ['Book'] }

    items do
      [
        build(:item,
              id: '1',
              barcode: '12345678',
              callnumber: 'ABC 123',
              status: 'Available',
              effective_location: build(:scannable_location, code: 'SAL3-STACKS')),
        build(:item,
              id: '2',
              barcode: '87654321',
              callnumber: 'ABC 321',
              status: 'Available',
              effective_location: build(:scannable_location, code: 'SAL3-STACKS'))
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :green_holdings, class: 'Folio::Instance' do
    id { '1234' }
    title { 'Green Item Title' }

    format { ['Book'] }

    items do
      [
        build(:item,
              barcode: '12345678',
              callnumber: 'ABC 123',
              status: 'Available',
              effective_location: build(:green_location))
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :page_lp_holdings, class: 'Folio::Instance' do
    id { '1234' }
    title { 'PAGE-LP Item Title' }

    format { ['Book'] }

    items do
      [
        build(:item,
              barcode: '12345678',
              callnumber: 'ABC 123',
              status: 'Available',
              effective_location: build(:page_lp_location))
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :page_en_holdings, class: 'Folio::Instance' do
    id { '1234' }
    title { 'PAGE-EN Item Title' }

    format { ['Book'] }

    items do
      [
        build(:item,
              barcode: '12345678',
              callnumber: 'ABC 123',
              status: 'Available',
              effective_location: build(:page_en_location))
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
        build(:item,
              barcode: '12345678',
              callnumber: 'ABC 123',
              status: 'Available',
              effective_location: build(:page_mp_location)),
        build(:item,
              barcode: '87654321',
              callnumber: 'ABC 321',
              status: 'Available',
              effective_location: build(:page_mp_location))
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
        build(:item,
              barcode: '12345678',
              callnumber: 'ABC 123',
              effective_location: build(:location, code: 'SAL3-STACKS')),
        build(:item,
              barcode: '23456789',
              callnumber: 'ABC 456',
              effective_location: build(:location, code: 'SAL3-STACKS')),
        build(:item,
              barcode: '34567890',
              callnumber: 'ABC 789',
              effective_location: build(:location, code: 'SAL3-STACKS')),
        build(:item,
              barcode: '45678901',
              callnumber: 'ABC 012',
              effective_location: build(:location, code: 'SAL3-STACKS'),
              public_note: 'note for 45678901'),
        build(:item,
              barcode: '56789012',
              callnumber: 'ABC 345',
              effective_location: build(:location, code: 'SAL3-STACKS')),
        build(:item,
              barcode: '67890123',
              callnumber: 'ABC 678',
              effective_location: build(:location, code: 'SAL3-STACKS'))
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :single_mediated_holding, class: 'Folio::Instance' do
    id { '1234' }
    title { 'Item Title' }

    format { ['Book'] }

    items do
      [
        build(:item,
              barcode: '12345678',
              callnumber: 'ABC 123',
              effective_location: build(:mediated_location, code: 'ART-LOCKED-LARGE'),
              type: 'LCKSTK')
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :art_stacks_holding, class: 'Folio::Instance' do
    id { '1234' }
    title { 'Item Title' }

    format { ['Book'] }

    items do
      [
        build(:item,
              barcode: '12345678',
              callnumber: 'ABC 123',
              effective_location: build(:location, code: 'ART-STACKS'),
              type: 'STKS')
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
        build(:item,
              id: 'a',
              barcode: '12345678',
              callnumber: 'ABC 123',
              effective_location: build(:mediated_location, code: 'ART-LOCKED-LARGE'),
              type: 'LCKSTK'),
        build(:item,
              id: 'b',
              barcode: '23456789',
              callnumber: 'ABC 456',
              effective_location: build(:mediated_location, code: 'ART-LOCKED-LARGE'),
              public_note: 'note for 23456789',
              type: 'LCKSTK'),
        build(:item,
              id: 'c',
              barcode: '34567890',
              callnumber: 'ABC 789',
              effective_location: build(:mediated_location, code: 'ART-NEWBOOK'),
              permanent_location: build(:mediated_location, code: 'ART-LOCKED-LARGE'),
              type: 'LCKSTK'),
        build(:item,
              id: 'd',
              barcode: '45678901',
              callnumber: 'ABC 012',
              effective_location: build(:mediated_location, code: 'ART-LOCKED-LARGE'),
              public_note: 'note for 45678901',
              type: 'LCKSTK'),
        build(:item,
              id: 'e',
              barcode: '56789012',
              callnumber: 'ABC 345',
              effective_location: build(:mediated_location, code: 'ART-LOCKED-LARGE'),
              type: 'LCKSTK'),
        build(:item,
              id: 'f',
              barcode: '67890123',
              callnumber: 'ABC 678',
              effective_location: build(:mediated_location, code: 'ART-LOCKED-LARGE'),
              type: 'LCKSTK'),
        build(:item,
              id: 'g',
              barcode: '78901234',
              callnumber: 'ABC 901',
              effective_location: build(:mediated_location, code: 'ART-LOCKED-LARGE'),
              type: 'LCKSTK'),
        build(:item,
              id: 'h',
              barcode: '89012345',
              callnumber: 'ABC 234',
              effective_location: build(:mediated_location, code: 'ART-LOCKED-LARGE'),
              type: 'LCKSTK'),
        build(:item,
              id: 'i',
              barcode: '90123456',
              callnumber: 'ABC 567',
              effective_location: build(:mediated_location, code: 'ART-LOCKED-LARGE'),
              type: 'LCKSTK'),
        build(:item,
              id: 'j',
              barcode: '01234567',
              callnumber: 'ABC 890',
              effective_location: build(:mediated_location, code: 'ART-LOCKED-LARGE'),
              type: 'LCKSTK')
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
        build(:item,
              barcode: '12345678',
              callnumber: 'ABC 123',
              effective_location: build(:spec_coll_location)),
        build(:item,
              barcode: '23456789',
              callnumber: 'ABC 456',
              effective_location: build(:spec_coll_location)),
        build(:item,
              barcode: '34567890',
              callnumber: 'ABC 789',
              effective_location: build(:spec_coll_location)),
        build(:item,
              barcode: '45678901',
              callnumber: 'ABC 012',
              effective_location: build(:spec_coll_location),
              public_note: 'note for 45678901'),
        build(:item,
              barcode: '56789012',
              callnumber: 'ABC 345',
              effective_location: build(:spec_coll_location)),
        build(:item,
              barcode: '67890123',
              callnumber: 'ABC 678',
              effective_location: build(:spec_coll_location)),
        build(:item,
              barcode: '78901234',
              callnumber: 'ABC 901',
              effective_location: build(:spec_coll_location)),
        build(:item,
              barcode: '89012345',
              callnumber: 'ABC 234',
              effective_location: build(:spec_coll_location)),
        build(:item,
              barcode: '90123456',
              callnumber: 'ABC 567',
              effective_location: build(:spec_coll_location)),
        build(:item,
              barcode: '01234567',
              callnumber: 'ABC 890',
              effective_location: build(:spec_coll_location))
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :checkedout_holdings, class: 'Folio::Instance' do
    id { '1234' }
    hrid { 'a1234' }
    title { 'Checked out item' }
    contributors { [{ 'primary' => true, 'name' => 'John Q. Public' }] }
    isbn { ['978-3-16-148410-0'] }
    oclcn { ['(OCoLC-M)1294477572'] }
    pub_date { '2018' }
    pub_place { 'Berlin' }
    publisher { 'Walter de Gruyter GmbH' }
    edition { ['1st ed.'] }

    format { ['Book'] }

    items do
      [
        build(:item,
              barcode: '12345678',
              callnumber: 'ABC 123',
              effective_location: build(:location, code: 'SAL3-STACKS')),
        build(:item,
              barcode: '87654321',
              callnumber: 'ABC 321',
              due_date: '2015-01-01T12:59:00.000+00:00',
              status: 'Checked out',
              enumeration: 'T.1 2023',
              effective_location: build(:location, code: 'SAL3-STACKS'))
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :sal3_stacks_searchworks_item, class: 'Folio::Instance' do
    id { '1234' }
    title { 'SAL3 stacks item' }

    format { ['Book'] }

    items do
      [
        build(:item,
              barcode: '12345678',
              callnumber: 'ABC 123',
              effective_location: build(:location, code: 'SAL3-STACKS'))
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :on_order_instance, class: 'Folio::Instance' do
    id { 'a43e597a-d4b4-50ec-ad16-7fd49920831a' }

    title { 'HAZARDOUS MATERIALS : MANAGING THE INCIDENT.' }

    format { 'unspecified' }

    items { [] }

    initialize_with do
      new(**attributes)
    end
  end

  factory :single_holding_multiple_items, class: 'Folio::Instance' do
    id { '1234' }
    hrid { 'a1234' }
    title { 'Multiple Items In Holding Title' }
    contributors { [{ 'primary' => true, 'name' => 'John Q. Public' }] }
    pub_date { '2018' }

    format { ['Book'] }

    items do
      [
        build(:item,
              barcode: '12345678',
              callnumber: 'ABC 123',
              status: 'Available',
              effective_location: build(:location, code: 'SAL3-STACKS')),
        build(:item,
              barcode: '12345679',
              callnumber: 'ABC 123',
              status: 'Available',
              effective_location: build(:location, code: 'SAL3-STACKS'))
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :mixed_crez_holdings, class: 'Folio::Instance' do
    id { '1234' }
    hrid { 'a1234' }
    title { 'Mixed CREZ holdings' }
    contributors { [{ 'primary' => true, 'name' => 'John Q. Public' }] }
    pub_date { '2018' }

    format { ['Book'] }

    items do
      [
        build(:item,
              barcode: '12345678',
              callnumber: 'ABC 123',
              status: 'Available',
              effective_location: build(:location, code: 'SAL3-STACKS')),
        build(:item,
              barcode: '87654321',
              callnumber: 'ABC 321',
              status: 'Available',
              effective_location: build(:location, code: 'GRE-CRES'),
              permanent_location: build(:location, code: 'SAL3-STACKS'),
              temporary_location: build(:location, code: 'GRE-CRES'))
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :empty_barcode_holdings, class: 'Folio::Instance' do
    id { '1234' }
    title { 'Empty Barcode Item Title' }
    contributors { [{ 'primary' => true, 'name' => 'John Q. Public' }] }
    pub_date { '2018' }

    format { ['Book'] }

    items do
      [
        build(:item,
              id: 'uuid-a',
              barcode: '12345678',
              callnumber: 'ABC 123',
              status: 'Available',
              effective_location: build(:location, code: 'SAL3-STACKS')),
        build(:item,
              id: 'uuid-b',
              barcode: '',
              callnumber: 'ABC 456',
              status: 'Available',
              effective_location: build(:location, code: 'SAL3-STACKS'))
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :missing_holdings, class: 'Folio::Instance' do
    id { '1234' }
    title { 'One Missing item' }

    format { ['Book'] }

    items do
      [
        build(:item,
              barcode: '12345678',
              callnumber: 'ABC 123',
              status: 'Missing',
              effective_location: build(:location, code: 'SAL3-STACKS')),
        build(:item,
              barcode: '12345678',
              callnumber: 'ABC 321',
              status: 'Available',
              effective_location: build(:location, code: 'SAL3-STACKS'))
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end

  factory :aged_to_lost_holdings, class: 'Folio::Instance' do
    id { '1234' }
    title { 'One lost item' }

    format { ['Book'] }

    items do
      [
        build(:item,
              barcode: '12345678',
              callnumber: 'ABC 123',
              status: 'Aged to Lost',
              effective_location: build(:location, code: 'SAL3-STACKS'))
      ]
    end

    initialize_with do
      new(**attributes)
    end
  end
end

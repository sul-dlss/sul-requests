# frozen_string_literal: true

if Settings.ils.bib_model == 'Folio::Instance'

  FactoryBot.define do
    factory :location, class: 'Folio::Location' do
      id { Folio::Types.get_type('locations').find { |l| l['code'] == code }.fetch('id') }
      code { 'SAL3-STACKS' }
      name { 'Location name' }
      discovery_display_name { 'Discovery display name' }
      campus { Folio::Campus.new(id: 'uuid', code: 'SUL') }
      library { Folio::Library.new(id: 'uuid', code: 'LIB') }
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
      id { SecureRandom.uuid }
      barcode { '3610512345678' }
      callnumber { 'ABC 123' }
      status { 'Available' }
      public_note { '' }
      type { '' }
      material_type { build(:book_material_type) }
      loan_type { Folio::LoanType.new(id: '') }
      effective_location_id { '4573e824-9273-4f13-972f-cff7bf504217' }
      # effective_location { build(:location, code: 'GRE-STACKS') }
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
                effective_location_id: '1146c4fa-5798-40e1-9b8e-92ee4c9f2ee2'),
          build(:item,
                barcode: '3610587654321',
                callnumber: 'ABC 321',
                effective_location_id: '1146c4fa-5798-40e1-9b8e-92ee4c9f2ee2'),
          build(:item,
                barcode: '12345679',
                callnumber: 'ABC 456',
                effective_location_id: '1146c4fa-5798-40e1-9b8e-92ee4c9f2ee2')
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
                effective_location_id: '1146c4fa-5798-40e1-9b8e-92ee4c9f2ee2')
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
                effective_location_id: '1146c4fa-5798-40e1-9b8e-92ee4c9f2ee2')
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
                status: 'Page',
                effective_location_id: '0902cbec-8afd-4307-948c-4995a48e160a'),
          build(:item,
                barcode: '87654321',
                callnumber: 'ABC 321',
                status: 'Page',
                effective_location_id: '0902cbec-8afd-4307-948c-4995a48e160a')
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
                status: 'Page',
                effective_location_id: '0902cbec-8afd-4307-948c-4995a48e160a'),
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
          build(:item,
                barcode: '12345678',
                callnumber: 'ABC 123',
                status: 'Page',
                effective_location_id: '0902cbec-8afd-4307-948c-4995a48e160a')
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
                status: 'Page',
                effective_location_id: '1146c4fa-5798-40e1-9b8e-92ee4c9f2ee2'),
          build(:item,
                barcode: '87654321',
                callnumber: 'ABC 321',
                status: 'Page',
                effective_location_id: '1146c4fa-5798-40e1-9b8e-92ee4c9f2ee2')
        ]
      end

      initialize_with do
        new(**attributes)
      end
    end

    factory :scannable_holdings, class: 'Folio::Instance' do
      id { '1234' }
      title { 'SAL Item Title' }

      format { ['Book'] }

      items do
        [
          build(:item,
                barcode: '12345678',
                callnumber: 'ABC 123',
                status: 'Page',
                effective_location_id: '1146c4fa-5798-40e1-9b8e-92ee4c9f2ee2'),
                # effective_location: build(:scannable_location, code: 'SAL3-STACKS')),
          build(:item,
                barcode: '87654321',
                callnumber: 'ABC 321',
                status: 'Page',
                effective_location_id: '1146c4fa-5798-40e1-9b8e-92ee4c9f2ee2')
                # effective_location: build(:scannable_location, code: 'SAL3-STACKS'))
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
                effective_location_id: '4573e824-9273-4f13-972f-cff7bf504217')
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
                status: 'Page',
                effective_location_id: 'b0402b41-91a9-4ec3-8c91-47e725e7fdf5')
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
                status: 'Page',
                effective_location_id: '398e87b0-35fb-4f80-bb79-b5f70a9a1bc6'),
          build(:item,
                barcode: '87654321',
                callnumber: 'ABC 321',
                status: 'Page',
                effective_location_id: '398e87b0-35fb-4f80-bb79-b5f70a9a1bc6')
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
                effective_location_id: '1146c4fa-5798-40e1-9b8e-92ee4c9f2ee2'),
                # effective_location: build(:location, code: 'SAL3-STACKS')),
          build(:item,
                barcode: '23456789',
                callnumber: 'ABC 456',
                effective_location_id: '1146c4fa-5798-40e1-9b8e-92ee4c9f2ee2'),
                # effective_location: build(:location, code: 'SAL3-STACKS')),
          build(:item,
                barcode: '34567890',
                callnumber: 'ABC 789',
                effective_location_id: '1146c4fa-5798-40e1-9b8e-92ee4c9f2ee2'),
                # effective_location: build(:location, code: 'SAL3-STACKS')),
          build(:item,
                barcode: '45678901',
                callnumber: 'ABC 012',
                effective_location_id: '1146c4fa-5798-40e1-9b8e-92ee4c9f2ee2',
                # effective_location: build(:location, code: 'SAL3-STACKS'),
                public_note: 'note for 45678901'),
          build(:item,
                barcode: '56789012',
                callnumber: 'ABC 345',
                effective_location_id: '1146c4fa-5798-40e1-9b8e-92ee4c9f2ee2'),
                # effective_location: build(:location, code: 'SAL3-STACKS')),
          build(:item,
                barcode: '67890123',
                callnumber: 'ABC 678',
                effective_location_id: '1146c4fa-5798-40e1-9b8e-92ee4c9f2ee2')
                # effective_location: build(:location, code: 'SAL3-STACKS'))
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
                effective_location_id: '6babb3e3-fc13-4762-a03f-d15fdf10c756',
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
                barcode: '12345678',
                callnumber: 'ABC 123',
                effective_location_id: '6babb3e3-fc13-4762-a03f-d15fdf10c756',
                type: 'LCKSTK'),
          build(:item,
                barcode: '23456789',
                callnumber: 'ABC 456',
                effective_location_id: '6babb3e3-fc13-4762-a03f-d15fdf10c756',
                public_note: 'note for 23456789',
                type: 'LCKSTK'),
          build(:item,
                barcode: '34567890',
                callnumber: 'ABC 789',
                effective_location_id: 'd38e7d81-f22d-41ee-8e1b-d73a22a4f23b',
                permanent_location_id: '6babb3e3-fc13-4762-a03f-d15fdf10c756',
                type: 'LCKSTK'),
          build(:item,
                barcode: '45678901',
                callnumber: 'ABC 012',
                effective_location_id: '6babb3e3-fc13-4762-a03f-d15fdf10c756',
                public_note: 'note for 45678901',
                type: 'LCKSTK'),
          build(:item,
                barcode: '56789012',
                callnumber: 'ABC 345',
                effective_location_id: '6babb3e3-fc13-4762-a03f-d15fdf10c756',
                type: 'LCKSTK'),
          build(:item,
                barcode: '67890123',
                callnumber: 'ABC 678',
                effective_location_id: '6babb3e3-fc13-4762-a03f-d15fdf10c756',
                type: 'LCKSTK'),
          build(:item,
                barcode: '78901234',
                callnumber: 'ABC 901',
                effective_location_id: '6babb3e3-fc13-4762-a03f-d15fdf10c756',
                type: 'LCKSTK'),
          build(:item,
                barcode: '89012345',
                callnumber: 'ABC 234',
                effective_location_id: '6babb3e3-fc13-4762-a03f-d15fdf10c756',
                type: 'LCKSTK'),
          build(:item,
                barcode: '90123456',
                callnumber: 'ABC 567',
                effective_location_id: '6babb3e3-fc13-4762-a03f-d15fdf10c756',
                type: 'LCKSTK'),
          build(:item,
                barcode: '01234567',
                callnumber: 'ABC 890',
                effective_location_id: '6babb3e3-fc13-4762-a03f-d15fdf10c756',
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
                effective_location_id: '0902cbec-8afd-4307-948c-4995a48e160a'),
          build(:item,
                barcode: '23456789',
                callnumber: 'ABC 456',
                effective_location_id: '0902cbec-8afd-4307-948c-4995a48e160a'),
          build(:item,
                barcode: '34567890',
                callnumber: 'ABC 789',
                effective_location_id: '0902cbec-8afd-4307-948c-4995a48e160a'),
          build(:item,
                barcode: '45678901',
                callnumber: 'ABC 012',
                effective_location_id: '0902cbec-8afd-4307-948c-4995a48e160a',
                public_note: 'note for 45678901'),
          build(:item,
                barcode: '56789012',
                callnumber: 'ABC 345',
                effective_location_id: '0902cbec-8afd-4307-948c-4995a48e160a'),
          build(:item,
                barcode: '67890123',
                callnumber: 'ABC 678',
                effective_location_id: '0902cbec-8afd-4307-948c-4995a48e160a'),
          build(:item,
                barcode: '78901234',
                callnumber: 'ABC 901',
                effective_location_id: '0902cbec-8afd-4307-948c-4995a48e160a'),
          build(:item,
                barcode: '89012345',
                callnumber: 'ABC 234',
                effective_location_id: '0902cbec-8afd-4307-948c-4995a48e160a'),
          build(:item,
                barcode: '90123456',
                callnumber: 'ABC 567',
                effective_location_id: '0902cbec-8afd-4307-948c-4995a48e160a'),
          build(:item,
                barcode: '01234567',
                callnumber: 'ABC 890',
                effective_location_id: '0902cbec-8afd-4307-948c-4995a48e160a'),
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
          build(:item,
                barcode: '12345678',
                callnumber: 'ABC 123',
                effective_location_id: '1146c4fa-5798-40e1-9b8e-92ee4c9f2ee2'),
          build(:item,
                barcode: '87654321',
                callnumber: 'ABC 321',
                status: 'Checked out',
                effective_location_id: '1146c4fa-5798-40e1-9b8e-92ee4c9f2ee2')
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
                effective_location_id: '1146c4fa-5798-40e1-9b8e-92ee4c9f2ee2',
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
  end
end

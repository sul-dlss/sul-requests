# frozen_string_literal: true

FactoryBot.define do
  factory :checkout, class: 'Folio::Checkout' do
    record do
      { 'id' => 'f4817e08-7118-44e1-a5ab-40fc30b29ff7',
        'item' =>
            { 'title' =>
              'Music, sound, language, theater',
              'author' => 'Crown Point Press (Oakland, Calif.)',
              'instanceId' => '7f3c7afd-4bfa-5166-a883-7016cbae016d',
              'itemId' => '30d507db-6ac5-5574-b83c-665bd1573c07',
              'isbn' => nil,
              'instance' =>
              { 'indexTitle' =>
                'Music, sound, language, theater' },
              'item' =>
              { 'barcode' => '36105020835901',
                'id' => '30d507db-6ac5-5574-b83c-665bd1573c07',
                'status' => { 'date' => '2023-06-03T06:08:56.901+00:00', 'name' => 'Checked out' },
                'effectiveShelvingOrder' => 'N 46494 C63 M87 41980 11',
                'effectiveCallNumberComponents' => { 'callNumber' => 'N6494 .C63 M87 1980' },
                'effectiveLocation' => { 'code' => 'ART-STACKS', 'library' => { 'code' => 'ART' } },
                'permanentLocation' => { 'code' => 'ART-STACKS' } } },
        'loanDate' => '2023-06-03T06:08:45.521+00:00',
        'dueDate' => '2020-09-27T06:59:59.000+00:00',
        'overdue' => false,
        'details' =>
            { 'renewalCount' => nil,
              'dueDateChangedByRecall' => nil,
              'dueDateChangedByHold' => nil,
              'proxyUserId' => 'bdfa62a1-758c-4389-ae81-8ddb37860f9b',
              'userId' => 'ec52d62d-9f0e-4ea5-856f-a1accb0121d1',
              'status' => { 'name' => 'Open' } } }
    end

    initialize_with { new(record, nil) }
  end

  factory :checkout_with_recall, parent: :checkout do
    record do
      { 'id' => '242c2dc3-6db5-40a1-a3ce-e1f27da86590',
        'item' =>
          { 'title' => 'Sci-fi architecture.',
            'author' => 'Toy, Maggie',
            'instanceId' => 'dbab2238-1a15-5ad8-af81-96805d798299',
            'itemId' => 'ac37b537-24a5-5fb7-8908-b798c1edb2e8',
            'isbn' => nil,
            'instance' => { 'indexTitle' => 'Sci-fi architecure.' },
            'item' =>
            { 'barcode' => '36105021987123',
              'id' => 'ac37b537-24a5-5fb7-8908-b798c1edb2e8',
              'status' => { 'date' => '2023-06-03T06:12:03.850+00:00', 'name' => 'Checked out' },
              'effectiveShelvingOrder' => 'NA 11 A16 V 269 NO 13 14 11',
              'effectiveCallNumberComponents' => { 'callNumber' => 'NA1 .A16' },
              'effectiveLocation' => { 'code' => 'ART-STACKS', 'library' => { 'code' => 'ART' } },
              'permanentLocation' => { 'code' => 'ART-STACKS' } } },
        'loanDate' => '2023-06-03T06:11:56.298+00:00',
        'dueDate' => '2023-09-27T06:59:59.000+00:00',
        'overdue' => false,
        'details' =>
          { 'renewalCount' => nil,
            'dueDateChangedByRecall' => true,
            'dueDateChangedByHold' => nil,
            'proxyUserId' => nil,
            'userId' => 'bdfa62a1-758c-4389-ae81-8ddb37860f9b',
            'status' => { 'name' => 'Open' } } }
    end
  end

  factory :overdue_checkout, parent: :checkout do
    record do
      { 'id' => 'f34e39a4-e6eb-4785-ab6d-d04627352577',
        'item' =>
           { 'title' =>
             '(RE)DISCOVERING THE OLMEC - NATIONAL GEOGRAPHIC SOCIETY-SMITHSONIAN INSTITUTION',
             'author' => 'LYON ROSEMARY DURKIN',
             'instanceId' => '3f82ea4e-55ef-5ba3-b316-77e1ee455a02',
             'itemId' => '5dfa4b14-f4ae-5bc8-b491-09919dd171c2',
             'isbn' => nil,
             'instance' =>
             { 'indexTitle' =>
               '(re)discovering the olmec - national geographic society-smithsonian institution' },
             'item' =>
             { 'barcode' => 'STA-12225730',
               'id' => '5dfa4b14-f4ae-5bc8-b491-09919dd171c2',
               'status' => { 'date' => '2023-08-24T07:22:00.183+00:00', 'name' => 'Aged to lost' },
               'effectiveShelvingOrder' => 'F 41219.1 V47 L96 41997 11',
               'effectiveCallNumberComponents' => { 'callNumber' => 'F1219.1.V47 L96 1997' },
               'effectiveLocation' => { 'code' => 'SUL-BORROW-DIRECT', 'library' => { 'code' => 'SUL' } },
               'permanentLocation' => { 'code' => 'SUL-BORROW-DIRECT' },
               'holdingsRecord' => { 'effectiveLocation' => { 'code' => 'SUL-BORROW-DIRECT' } } } },
        'loanDate' => '2023-06-21T16:12:27.891+00:00',
        'dueDate' => '2023-08-17T06:59:59.000+00:00',
        'overdue' => true,
        'details' =>
           { 'renewalCount' => nil,
             'dueDateChangedByRecall' => nil,
             'dueDateChangedByHold' => nil,
             'proxyUserId' => nil,
             'userId' => 'd7b67ab1-a3f2-45a9-87cc-d867bca8315f',
             'status' => { 'name' => 'Open' },
             'feesAndFines' => { 'amountRemainingToPay' => 200 } } }
    end
  end

  factory :request, class: 'Folio::Request' do
    transient do
      custom_properties { {} } # Properties you can override in the test cases
    end

    record do
      { 'requestDate' => '2023-06-26T17:45:01.000+00:00',
        'item' =>
           { 'instanceId' => '818d9d5e-1007-5bc8-8cfd-04fce963fbc6',
             'title' => 'And the cat says... / Susan L. Helwig.',
             'itemId' => 'ec3e386b-7a67-5889-b329-b02fec9d822c',
             'item' =>
             { 'circulationNotes' => [],
               'effectiveShelvingOrder' => 'PR 49199.4 H45 A64 42013 11',
               'effectiveCallNumberComponents' => { 'callNumber' => 'PR9199.4 .H45 A64 2013' },
               'effectiveLocation' => { 'id' => '1146c4fa-5798-40e1-9b8e-92ee4c9f2ee2', 'code' => 'SAL3-STACKS',
                                        'library' => { 'id' => 'ddd3bce1-9f8f-4448-8d6d-b6c1b3907ba9', 'code' => 'SAL3' },
                                        'details' => { 'pageServicePoints' => [] } } },
             'author' => 'Helwig, Susan L., 1950-',
             'instance' => { 'hrid' => 'a10156831' },
             'isbn' => nil },
        'requestId' => 'c7691ab1-9660-4291-a5f7-562cceb1c8a2',
        'status' => 'Open___Not_yet_filled',
        'expirationDate' => '2023-10-21T06:59:59.000+00:00',
        'details' => { 'holdShelfExpirationDate' => nil, 'proxyUserId' => nil, 'proxy' => nil },
        'pickupLocationId' => 'a5dbb3dc-84f8-4eb3-8bfe-c61f74a9e92d',
        'pickupLocation' => { 'code' => 'GREEN-LOAN' },
        'queueTotalLength' => 1,
        'queuePosition' => 1,
        'cancellationReasonId' => nil,
        'canceledByUserId' => nil,
        'cancellationAdditionalInformation' => nil,
        'canceledDate' => nil,
        'patronComments' => nil }.deep_merge(custom_properties)
    end

    initialize_with { new(record) }
  end
end

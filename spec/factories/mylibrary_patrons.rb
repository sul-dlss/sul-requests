# frozen_string_literal: true

FactoryBot.define do
  factory :sponsor_patron, class: 'Folio::Patron' do
    transient do
      custom_properties { {} } # Properties you can override in the test cases
    end

    patron_info do
      { 'user' =>
        { 'username' => 'Sponsor1',
          'id' => 'ec52d62d-9f0e-4ea5-856f-a1accb0121d1',
          'barcode' => 'Sponsor1',
          'active' => true,
          'personal' =>
          { 'email' => 'superuser1@stanford.edu',
            'lastName' => 'Sponsor',
            'firstName' => 'Shea',
            'preferredFirstName' => nil },
          'proxiesFor' => [],
          'proxiesOf' =>
          [{ 'proxyUserId' => 'bdfa62a1-758c-4389-ae81-8ddb37860f9b',
             'proxyUser' => { 'barcode' => 'Proxy1',
                              'personal' => { 'firstName' => 'Piper', 'lastName' => 'Proxy' } } },
           { 'proxyUserId' => '8e03792c-e673-43c2-a412-a3796d7c8f7e',
             'proxyUser' => { 'barcode' => 'grad1',
                              'personal' => { 'firstName' => 'Gene', 'lastName' => 'Graduate' } } }],
          'expirationDate' => nil,
          'externalSystemId' => nil,
          'patronGroup' =>
          { 'id' => '503a81cd-6c26-400f-b620-14c08943697c',
            'desc' => 'Faculty Member',
            'group' => 'faculty',
            'limits' =>
            [{ 'conditionId' => 'e5b45031-a202-4abb-917b-e1df9346fe2c',
               'id' => 'eb2fd828-c113-45c7-862d-856cd83ec3e6',
               'patronGroupId' => '503a81cd-6c26-400f-b620-14c08943697c',
               'value' => 2,
               'condition' =>
               { 'blockBorrowing' => true,
                 'blockRenewals' => false,
                 'blockRequests' => false,
                 'message' =>
                 'You have recalled library materials that must be returned. Your account is blocked.',
                 'name' => 'Maximum number of overdue recalls',
                 'valueType' => 'Integer' } },
             { 'conditionId' => 'cf7a0d5f-a327-4ca1-aa9e-dc55ec006b8a',
               'id' => '24054288-d929-4271-bcf0-fabb5add53fb',
               'patronGroupId' => '503a81cd-6c26-400f-b620-14c08943697c',
               'value' => 300,
               'condition' =>
               { 'blockBorrowing' => true,
                 'blockRenewals' => true,
                 'blockRequests' => false,
                 'message' => 'You have fees and fines to pay. Your account is blocked.',
                 'name' => 'Maximum outstanding fee/fine balance',
                 'valueType' => 'Double' } },
             { 'conditionId' => '08530ac4-07f2-48e6-9dda-a97bc2bf7053',
               'id' => '7b9cb6a8-d8fb-4c68-9166-67a369c50245',
               'patronGroupId' => '503a81cd-6c26-400f-b620-14c08943697c',
               'value' => 7,
               'condition' =>
               { 'blockBorrowing' => false,
                 'blockRenewals' => false,
                 'blockRequests' => false,
                 'message' => '',
                 'name' => 'Recall overdue by maximum number of days',
                 'valueType' => 'Integer' } }] },
          'blocks' => [],
          'manualBlocks' => [] },
        'id' => 'ec52d62d-9f0e-4ea5-856f-a1accb0121d1',
        'holds' =>
        [{ 'requestDate' => '2023-06-16T17:56:23.000+00:00',
           'item' =>
          { 'instanceId' => '4cd4ba91-394f-5efc-b867-75583a284583',
            'title' =>
            'Rothko : the color field paintings',
            'itemId' => '250cdadc-189b-5658-b2a9-c7d2fc31ab9b',
            'item' =>
            { 'circulationNotes' => [],
              'effectiveShelvingOrder' => 'ND237 R725 A4 2017 F',
              'effectiveCallNumberComponents' => { 'callNumber' => 'ND237 .R725 A4 2017 F' },
              'effectiveLocation' => { 'code' => 'SAL3-STACKS', 'library' => { 'code' => 'SAL3' } } },
            'author' => 'Watson, Robert Grant',
            'instance' => { 'hrid' => 'a14439363' },
            'isbn' => nil },
           'requestId' => '7fa87cfe-df57-4dc7-953b-a5a44ff37d91',
           'status' => 'Open___Awaiting_pickup',
           'expirationDate' => '2023-07-27T06:59:59.000+00:00',
           'details' => { 'holdShelfExpirationDate' => nil, 'proxyUserId' => nil, 'proxy' => nil },
           'pickupLocationId' => 'a5dbb3dc-84f8-4eb3-8bfe-c61f74a9e92d',
           'pickupLocation' => { 'code' => 'GREEN-LOAN' },
           'queueTotalLength' => 4,
           'queuePosition' => 3,
           'cancellationReasonId' => nil,
           'canceledByUserId' => nil,
           'cancellationAdditionalInformation' => nil,
           'canceledDate' => nil,
           'patronComments' => nil },
         { 'requestDate' => '2023-06-16T17:56:23.000+00:00',
           'item' =>
           { 'instanceId' => '4cd4ba91-394f-5efc-b867-75583a284583',
             'title' =>
             'Rothko : the color field paintings',
             'itemId' => '250cdadc-189b-5658-b2a9-c7d2fc31ab9b',
             'item' =>
             { 'circulationNotes' => [],
               'effectiveShelvingOrder' => 'ND237 R725 A4 2017 F',
               'effectiveCallNumberComponents' => { 'callNumber' => 'ND237 .R725 A4 2017 F' },
               'effectiveLocation' => { 'code' => 'SAL3-STACKS', 'library' => { 'code' => 'SAL3' } } },
             'author' => 'Watson, Robert Grant',
             'instance' => { 'hrid' => 'a14439363' },
             'isbn' => nil },
           'requestId' => '7fa87cfe-df57-4dc7-953b-a5a44ff37d91',
           'status' => 'Open___Awaiting_pickup',
           'expirationDate' => '2023-07-27T06:59:59.000+00:00',
           'details' => { 'holdShelfExpirationDate' => nil, 'proxyUserId' => nil, 'proxy' => nil },
           'pickupLocationId' => 'a5dbb3dc-84f8-4eb3-8bfe-c61f74a9e92d',
           'pickupLocation' => { 'code' => 'GREEN-LOAN' },
           'queueTotalLength' => 4,
           'queuePosition' => 3,
           'cancellationReasonId' => nil,
           'canceledByUserId' => nil,
           'cancellationAdditionalInformation' => nil,
           'canceledDate' => nil,
           'patronComments' => nil },
         { 'requestDate' => '2023-06-16T17:56:23.000+00:00',
           'item' =>
           { 'instanceId' => '4cd4ba91-394f-5efc-b867-75583a284583',
             'title' =>
             'Understanding May Sarton',
             'itemId' => '250cdadc-189b-5658-b2a9-c7d2fc31ab9b',
             'item' =>
             { 'circulationNotes' => [],
               'effectiveShelvingOrder' => 'DS 3298 W3 42023 11',
               'effectiveCallNumberComponents' => { 'callNumber' => 'DS298 .W3 2023' },
               'effectiveLocation' => { 'code' => 'SAL3-STACKS', 'library' => { 'code' => 'SAL3' } } },
             'author' => 'Watson, Robert Grant',
             'instance' => { 'hrid' => 'a14439363' },
             'isbn' => nil },
           'requestId' => '7fa87cfe-df57-4dc7-953b-a5a44ff37d91',
           'status' => 'Open___Not_yet_filled',
           'expirationDate' => '2023-07-27T06:59:59.000+00:00',
           'details' => { 'holdShelfExpirationDate' => nil, 'proxyUserId' => nil, 'proxy' => nil },
           'pickupLocationId' => '8bb5d494-263f-42f0-9a9f-70451530d8a3',
           'pickupLocation' => { 'code' => 'CLASSICS' },
           'queueTotalLength' => 4,
           'queuePosition' => 3,
           'cancellationReasonId' => nil,
           'canceledByUserId' => nil,
           'cancellationAdditionalInformation' => nil,
           'canceledDate' => nil,
           'patronComments' => nil },
         { 'requestDate' => '2023-06-16T17:56:23.000+00:00',
           'item' =>
          { 'instanceId' => '4cd4ba91-394f-5efc-b867-75583a284583',
            'title' =>
            'A history of Persia',
            'itemId' => '250cdadc-189b-5658-b2a9-c7d2fc31ab9b',
            'item' =>
            { 'circulationNotes' => [],
              'effectiveShelvingOrder' => 'DS 3298 W3 42023 11',
              'effectiveCallNumberComponents' => { 'callNumber' => 'DS298 .W3 2023' },
              'effectiveLocation' => { 'code' => 'SAL3-STACKS', 'library' => { 'code' => 'SAL3' } } },
            'author' => 'Watson, Robert Grant',
            'instance' => { 'hrid' => 'a14439363' },
            'isbn' => nil },
           'requestId' => '7fa87cfe-df57-4dc7-953b-a5a44ff37d91',
           'status' => 'Open___Not_yet_filled',
           'expirationDate' => '2023-07-27T06:59:59.000+00:00',
           'details' => { 'holdShelfExpirationDate' => nil, 'proxyUserId' => nil, 'proxy' => nil },
           'pickupLocationId' => '8bb5d494-263f-42f0-9a9f-70451530d8a3',
           'pickupLocation' => { 'code' => 'CLASSICS' },
           'queueTotalLength' => 4,
           'queuePosition' => 3,
           'cancellationReasonId' => nil,
           'canceledByUserId' => nil,
           'cancellationAdditionalInformation' => nil,
           'canceledDate' => nil,
           'patronComments' => nil },
         { 'requestDate' => '2023-07-06T18:57:15.000+00:00',
           'item' =>
           { 'instanceId' => '99796220-1d4c-569f-bcf4-2bbe983b204f',
             'title' =>
             'Fiction!',
             'itemId' => 'e2271e84-896c-51e4-bc92-202eab13d0cd',
             'item' =>
             { 'circulationNotes' => [],
               'effectiveShelvingOrder' => 'PS 3129 T6 11',
               'effectiveCallNumberComponents' => { 'callNumber' => 'PS129 .T6' },
               'effectiveLocation' => { 'code' => 'SAL3-STACKS', 'library' => { 'code' => 'SAL3' } } },
             'author' => 'Tooker, Dan; Hofheins, Roger',
             'instance' => { 'hrid' => 'a910877' },
             'isbn' => nil },
           'requestId' => '572919e2-0817-49df-87bc-04c9775ae48d',
           'status' => 'Open___Not_yet_filled',
           'expirationDate' => '2023-07-27T06:59:59.000+00:00',
           'details' =>
           { 'holdShelfExpirationDate' => nil,
             'proxyUserId' => 'bdfa62a1-758c-4389-ae81-8ddb37860f9b',
             'proxy' => { 'firstName' => 'Piper', 'lastName' => 'Proxy', 'barcode' => 'Proxy1' } },
           'pickupLocationId' => '4827ae1d-b8bf-4b90-9e09-d642557893ab',
           'pickupLocation' => { 'code' => 'EARTH-SCI' },
           'queueTotalLength' => 1,
           'queuePosition' => 1,
           'cancellationReasonId' => nil,
           'canceledByUserId' => nil,
           'cancellationAdditionalInformation' => nil,
           'canceledDate' => nil,
           'patronComments' => 'testing a proxy hold' }],
        'accounts' => [{ 'id' => '6fe14d1d-1497-4077-aa16-f4f11b746a75',
                         'userId' => 'ec52d62d-9f0e-4ea5-856f-a1accb0121d1',
                         'remaining' => 150,
                         'amount' => 150,
                         'loanId' => 'f34e39a4-e6eb-4785-ab6d-d04627352577',
                         'loan' => { 'proxyUserId' => 'bdfa62a1-758c-4389-ae81-8ddb37860f9b' },
                         'status' => { 'name' => 'Open' },
                         'feeFine' => { 'feeFineType' => 'Lost item fee' },
                         'actions' => [{ 'dateAction' => '2023-08-24T07:52:00.730+00:00',
                                         'typeAction' => 'Lost item fee' }],
                         'paymentStatus' => { 'name' => 'Outstanding' },
                         'item' =>
{ 'id' => '5dfa4b14-f4ae-5bc8-b491-09919dd171c2',
  'effectiveLocation' => { 'library' => { 'name' => 'SUL' } },
  'instance' =>
{ 'title' =>
'Title borrowed by the sponsor',
  'contributors' => [{ 'name' => 'LYON ROSEMARY DURKIN' }] },
  'holdingsRecord' => { 'callNumber' => 'F1219.1.V47 L96 1997' } } }],
        'loans' =>
        [{ 'id' => 'f4817e08-7118-44e1-a5ab-40fc30b29ff7',
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
             'status' => { 'name' => 'Open' } } },
         { 'id' => 'e8d0dd5c-2b69-420f-bd91-075eebbe8eba',
           'item' =>
           { 'title' =>
             'See this sound',
             'author' => 'Daniels, Dieter; Naumann, Sandra; Thoben, Jan',
             'instanceId' => 'abdb8f6a-d3c3-5f7e-921c-0cfc4835f3bc',
             'itemId' => '95acc0f1-d699-5723-a89b-3329279a05d5',
             'isbn' => nil,
             'instance' => { 'indexTitle' => 'See this sound : audiovisuology : a reader' },
             'item' =>
             { 'barcode' => '36105224828744',
               'id' => '95acc0f1-d699-5723-a89b-3329279a05d5',
               'status' => { 'date' => '2023-06-03T06:09:34.414+00:00', 'name' => 'Checked out' },
               'effectiveShelvingOrder' => 'N 46494 M78 S44 42015 11',
               'effectiveCallNumberComponents' => { 'callNumber' => 'N6494 .M78 S44 2015' },
               'effectiveLocation' => { 'code' => 'ART-STACKS', 'library' => { 'code' => 'ART' } },
               'permanentLocation' => { 'code' => 'ART-STACKS' } } },
           'loanDate' => '2023-06-03T06:09:20.956+00:00',
           'dueDate' => '2020-09-27T06:59:59.000+00:00',
           'overdue' => false,
           'details' =>
           { 'renewalCount' => nil,
             'dueDateChangedByRecall' => nil,
             'dueDateChangedByHold' => nil,
             'proxyUserId' => 'bdfa62a1-758c-4389-ae81-8ddb37860f9b',
             'userId' => 'ec52d62d-9f0e-4ea5-856f-a1accb0121d1',
             'status' => { 'name' => 'Open' } } },
         { 'id' => '75d92250-2188-4b73-b2e5-aefae6d5e17f',
           'item' =>
           { 'title' =>
             'Blue-collar Broadway',
             'author' => 'White, Timothy R., 1976-',
             'instanceId' => 'fb3a04f7-04a3-5ffa-a383-f49a735e4e37',
             'itemId' => '3eb63eec-9ce5-5cf0-9d6e-2c6f16137aa3',
             'isbn' => nil,
             'instance' =>
             { 'indexTitle' => 'Blue-collar broadway : the craft and industry of american theater' },
             'item' =>
             { 'barcode' => '36105212981729',
               'id' => '3eb63eec-9ce5-5cf0-9d6e-2c6f16137aa3',
               'status' => { 'date' => '2023-06-03T06:10:58.000+00:00', 'name' => 'Checked out' },
               'effectiveShelvingOrder' => 'PN 42277 N7 W48 42015 11',
               'effectiveCallNumberComponents' => { 'callNumber' => 'PN2277 .N7 W48 2015' },
               'effectiveLocation' => { 'code' => 'GRE-STACKS', 'library' => { 'code' => 'GREEN' } },
               'permanentLocation' => { 'code' => 'GRE-STACKS' } } },
           'loanDate' => '2023-06-03T06:10:52.704+00:00',
           'dueDate' => '2020-09-27T06:59:59.000+00:00',
           'overdue' => false,
           'details' =>
           { 'renewalCount' => nil,
             'dueDateChangedByRecall' => nil,
             'dueDateChangedByHold' => nil,
             'proxyUserId' => nil,
             'userId' => 'ec52d62d-9f0e-4ea5-856f-a1accb0121d1',
             'status' => { 'name' => 'Open' } } }],
        'totalCharges' => { 'isoCurrencyCode' => 'USD', 'amount' => 0 },
        'totalChargesCount' => 0,
        'totalLoans' => 3,
        'totalHolds' => 2 }.merge(custom_properties)
    end

    initialize_with { new(patron_graphql_response: patron_info) }
  end

  factory :proxy_patron, class: 'Folio::Patron' do
    transient do
      custom_properties { {} } # Properties you can override in the test cases
    end

    patron_info do
      { 'user' =>
        { 'username' => 'Proxy1',
          'barcode' => 'Proxy1',
          'active' => true,
          'personal' =>
          { 'email' => 'proxy_patron@stanford.edu',
            'lastName' => 'Proxy',
            'firstName' => 'Piper',
            'preferredFirstName' => nil },
          'proxiesFor' => [{ 'userId' => 'ec52d62d-9f0e-4ea5-856f-a1accb0121d1' }],
          'proxiesOf' => [],
          'expirationDate' => nil,
          'externalSystemId' => nil,
          'patronGroup' =>
          { 'desc' => 'Graduate Student',
            'group' => 'graduate',
            'limits' =>
            [{ 'conditionId' => 'cf7a0d5f-a327-4ca1-aa9e-dc55ec006b8a',
               'id' => '3cf0f601-2cab-470e-b4a9-2f7459943686',
               'patronGroupId' => 'ad0bc554-d5bc-463c-85d1-5562127ae91b',
               'value' => 50,
               'condition' =>
               { 'blockBorrowing' => true,
                 'blockRenewals' => true,
                 'blockRequests' => false,
                 'message' => 'You have fees and fines to pay. Your account is blocked.',
                 'name' => 'Maximum outstanding fee/fine balance',
                 'valueType' => 'Double' } },
             { 'conditionId' => 'e5b45031-a202-4abb-917b-e1df9346fe2c',
               'id' => '862cc936-21ea-442a-9763-1c6f5989c11d',
               'patronGroupId' => 'ad0bc554-d5bc-463c-85d1-5562127ae91b',
               'value' => 2,
               'condition' =>
               { 'blockBorrowing' => true,
                 'blockRenewals' => false,
                 'blockRequests' => false,
                 'message' =>
                 'You have recalled library materials that must be returned. Your account is blocked.',
                 'name' => 'Maximum number of overdue recalls',
                 'valueType' => 'Integer' } },
             { 'conditionId' => '08530ac4-07f2-48e6-9dda-a97bc2bf7053',
               'id' => '830209d4-2110-4c1c-b943-0f8467884fe9',
               'patronGroupId' => 'ad0bc554-d5bc-463c-85d1-5562127ae91b',
               'value' => 7,
               'condition' =>
               { 'blockBorrowing' => false,
                 'blockRenewals' => false,
                 'blockRequests' => false,
                 'message' => '',
                 'name' => 'Recall overdue by maximum number of days',
                 'valueType' => 'Integer' } }] },
          'blocks' => [],
          'manualBlocks' => [] },
        'id' => 'bdfa62a1-758c-4389-ae81-8ddb37860f9b',
        'holds' =>
        [{ 'requestDate' => '2023-06-16T19:00:24.000+00:00',
           'item' =>
           { 'instanceId' => '4cd4ba91-394f-5efc-b867-75583a284583',
             'title' =>
             'A history of Persia',
             'itemId' => '250cdadc-189b-5658-b2a9-c7d2fc31ab9b',
             'item' =>
             { 'circulationNotes' => [],
               'effectiveShelvingOrder' => 'DS 3298 W3 42023 11',
               'effectiveCallNumberComponents' => { 'callNumber' => 'DS298 .W3 2023' },
               'effectiveLocation' => { 'code' => 'SAL3-STACKS', 'library' => { 'code' => 'SAL3' } } },
             'author' => 'Watson, Robert Grant',
             'instance' => { 'hrid' => 'a14439363' },
             'isbn' => nil },
           'requestId' => '5ae2588d-3c8e-49bd-9295-f2dedc336ae4',
           'status' => 'Open___Not_yet_filled',
           'expirationDate' => nil,
           'details' => { 'holdShelfExpirationDate' => nil, 'proxyUserId' => nil, 'proxy' => nil },
           'pickupLocationId' => '4d77d74b-271e-421a-91c6-992afa9afb3c',
           'pickupLocation' => { 'code' => 'MUSIC' },
           'queueTotalLength' => 4,
           'queuePosition' => 6,
           'cancellationReasonId' => nil,
           'canceledByUserId' => nil,
           'cancellationAdditionalInformation' => nil,
           'canceledDate' => nil,
           'patronComments' => nil }],
        'accounts' => [{ 'id' => '6fe14d1d-1497-4077-aa16-f4f11b746a75',
                         'userId' => 'bdfa62a1-758c-4389-ae81-8ddb37860f9b',
                         'remaining' => 200,
                         'amount' => 200,
                         'loanId' => 'f34e39a4-e6eb-4785-ab6d-d04627352577',
                         'loan' => { 'proxyUserId' => nil },
                         'status' => { 'name' => 'Open' },
                         'feeFine' => { 'feeFineType' => 'Lost item fee' },
                         'actions' => [{ 'dateAction' => '2023-08-24T07:52:00.730+00:00',
                                         'typeAction' => 'Lost item fee' }],
                         'paymentStatus' => { 'name' => 'Outstanding' },
                         'item' =>
          { 'id' => '5dfa4b14-f4ae-5bc8-b491-09919dd171c2',
            'effectiveLocation' => { 'library' => { 'name' => 'SUL' } },
            'instance' =>
            { 'title' =>
              '(RE)DISCOVERING THE OLMEC - NATIONAL GEOGRAPHIC SOCIETY-SMITHSONIAN INSTITUTION',
              'contributors' => [{ 'name' => 'LYON ROSEMARY DURKIN' }] },
            'holdingsRecord' => { 'callNumber' => 'F1219.1.V47 L96 1997' } } }],
        'loans' =>
        [{ 'id' => '242c2dc3-6db5-40a1-a3ce-e1f27da86590',
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
             'dueDateChangedByRecall' => nil,
             'dueDateChangedByHold' => nil,
             'proxyUserId' => nil,
             'userId' => 'bdfa62a1-758c-4389-ae81-8ddb37860f9b',
             'status' => { 'name' => 'Open' } } }],
        'totalCharges' => { 'isoCurrencyCode' => 'USD', 'amount' => 0 },
        'totalChargesCount' => 0,
        'totalLoans' => 1,
        'totalHolds' => 1 }.merge(custom_properties)
    end

    initialize_with { new(patron_graphql_response: patron_info) }
  end

  factory :groupless_patron, class: 'Folio::Patron' do
    transient do
      custom_properties { {} } # Properties you can override in the test cases
    end

    patron_info do
      { 'user' =>
        { 'username' => 'Groupless1',
          'barcode' => 'Groupless1',
          'active' => true,
          'personal' =>
          { 'email' => 'dlss-access-team@stanford.edu',
            'lastName' => 'Groupy',
            'firstName' => 'Granger',
            'preferredFirstName' => nil },
          'proxiesFor' => [],
          'proxiesOf' => [],
          'expirationDate' => nil,
          'externalSystemId' => nil,
          'patronGroup' => nil,
          'blocks' => [],
          'manualBlocks' => [] },
        'id' => 'bdfa62a1-758c-4389-ae81-8ddb37860f9b',
        'holds' => [],
        'accounts' => [],
        'loans' => [],
        'totalCharges' => { 'isoCurrencyCode' => 'USD', 'amount' => 0 },
        'totalChargesCount' => 0,
        'totalLoans' => 0,
        'totalHolds' => 0 }.merge(custom_properties)
    end

    initialize_with { new(patron_graphql_response: patron_info) }
  end

  factory :fee_borrower, class: 'Folio::Patron' do
    transient do
      custom_properties { {} } # Properties you can override in the test cases
    end

    patron_info do
      { 'user' =>
        { 'username' => 'Fee1',
          'barcode' => 'Fee1',
          'active' => true,
          'personal' =>
          { 'email' => 'dlss-access-team@stanford.edu',
            'lastName' => 'Freddie',
            'firstName' => 'Feelings',
            'preferredFirstName' => nil },
          'proxiesFor' => [],
          'proxiesOf' => [],
          'expirationDate' => nil,
          'externalSystemId' => nil,
          'patronGroup' => {
            'desc' => 'Fee borrower',
            'limits' =>
            [{
              'value' => 50,
              'condition' => {
                'name' => 'Maximum number of items charged out'
              }
            }]
          },
          'blocks' => [],
          'manualBlocks' => [] },
        'id' => 'bdfa62a1-758c-4389-ae81-8ddb37860f9b',
        'holds' => [],
        'accounts' => [],
        'loans' => [],
        'totalCharges' => { 'isoCurrencyCode' => 'USD', 'amount' => 0 },
        'totalChargesCount' => 0,
        'totalLoans' => 0,
        'totalHolds' => 0 }.merge(custom_properties)
    end

    initialize_with { new(patron_graphql_response: patron_info) }
  end

  factory :patron_with_overdue_items, class: 'Folio::Patron' do
    transient do
      custom_properties { {} } # Properties you can override in the test cases
    end

    patron_info do
      {
        'user' => { 'active' => true, 'manualBlocks' => [], 'blocks' => [] },
        'loans' => [{ 'id' => '242c2dc3-6db5-40a1-a3ce-e1f27da86590',
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
                      'overdue' => true,
                      'details' =>
          { 'renewalCount' => nil,
            'feesAndFines' => { 'amountRemainingToPay' => 30 },
            'dueDateChangedByRecall' => nil,
            'dueDateChangedByHold' => nil,
            'proxyUserId' => nil,
            'userId' => 'bdfa62a1-758c-4389-ae81-8ddb37860f9b',
            'status' => { 'name' => 'Open' } } }],
        'holds' => [],
        'accounts' => []
      }.merge(custom_properties)
    end

    initialize_with { new(patron_graphql_response: patron_info) }
  end

  factory :patron_with_recalls, class: 'Folio::Patron' do
    transient do
      custom_properties { {} } # Properties you can override in the test cases
    end

    patron_info do
      {
        'user' => { 'active' => true, 'manualBlocks' => [], 'blocks' => [] },
        'loans' => [{ 'id' => '242c2dc3-6db5-40a1-a3ce-e1f27da86590',
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
            'status' => { 'name' => 'Open' } } }],
        'holds' => [],
        'accounts' => []
      }.merge(custom_properties)
    end

    initialize_with { new(patron_graphql_response: patron_info) }
  end

  factory :patron_with_fines, class: 'Folio::Patron' do
    transient do
      custom_properties { {} } # Properties you can override in the test cases
    end

    patron_info do
      { 'user' =>
        { 'username' => 'Blocked1',
          'id' => 'e705b594-1e94-4195-a4a3-fd50031cdacd',
          'barcode' => 'Blocked1',
          'active' => true,
          'personal' => { 'email' => 'dlss-access-team@stanford.edu', 'lastName' => 'Blocked', 'firstName' => 'Books',
                          'preferredFirstName' => nil },
          'proxiesFor' => [],
          'proxiesOf' => [],
          'expirationDate' => nil,
          'externalSystemId' => nil,
          'patronGroup' =>
          { 'desc' => 'Undergraduate Student',
            'group' => 'undergrad',
            'limits' =>
            [{ 'conditionId' => 'cf7a0d5f-a327-4ca1-aa9e-dc55ec006b8a',
               'id' => '2b89bbe2-9324-43c1-a99b-a370877f74ad',
               'patronGroupId' => 'bdc2b6d4-5ceb-4a12-ab46-249b9a68473e',
               'value' => 50,
               'condition' =>
               { 'blockBorrowing' => true,
                 'blockRenewals' => true,
                 'blockRequests' => false,
                 'message' => 'You have fees and fines to pay. Your account is blocked.',
                 'name' => 'Maximum outstanding fee/fine balance',
                 'valueType' => 'Double' } },
             { 'conditionId' => 'e5b45031-a202-4abb-917b-e1df9346fe2c',
               'id' => '84b7fbff-4d5d-489b-a538-1cfd5fe8716b',
               'patronGroupId' => 'bdc2b6d4-5ceb-4a12-ab46-249b9a68473e',
               'value' => 2,
               'condition' =>
               { 'blockBorrowing' => true,
                 'blockRenewals' => false,
                 'blockRequests' => false,
                 'message' => 'You have recalled library materials that must be returned. Your account is blocked.',
                 'name' => 'Maximum number of overdue recalls',
                 'valueType' => 'Integer' } },
             { 'conditionId' => '08530ac4-07f2-48e6-9dda-a97bc2bf7053',
               'id' => '05f0b38e-471d-4de4-86c3-e1267e08670f',
               'patronGroupId' => 'bdc2b6d4-5ceb-4a12-ab46-249b9a68473e',
               'value' => 7,
               'condition' =>
               { 'blockBorrowing' => false,
                 'blockRenewals' => false,
                 'blockRequests' => false,
                 'message' => '',
                 'name' => 'Recall overdue by maximum number of days',
                 'valueType' => 'Integer' } }] },
          'blocks' => [{ 'message' => 'You have fees and fines to pay. Your account is blocked.' }],
          'manualBlocks' => [] },
        'id' => 'e705b594-1e94-4195-a4a3-fd50031cdacd',
        'holds' =>
        [{ 'requestDate' => '2023-06-26T17:45:01.000+00:00',
           'item' =>
           { 'instanceId' => '818d9d5e-1007-5bc8-8cfd-04fce963fbc6',
             'title' => 'And the cat says... / Susan L. Helwig.',
             'itemId' => 'ec3e386b-7a67-5889-b329-b02fec9d822c',
             'item' =>
             { 'circulationNotes' => [],
               'effectiveShelvingOrder' => 'PR 49199.4 H45 A64 42013 11',
               'effectiveCallNumberComponents' => { 'callNumber' => 'PR9199.4 .H45 A64 2013' },
               'effectiveLocation' => { 'code' => 'SAL3-STACKS', 'library' => { 'code' => 'SAL3' },
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
           'patronComments' => nil }],
        'accounts' =>
        [{ 'id' => 'd7fc8950-a5ec-469a-b750-ea4c29519f99',
           'userId' => 'e705b594-1e94-4195-a4a3-fd50031cdacd',
           'remaining' => 325,
           'amount' => 325,
           'loanId' => nil,
           'loan' => nil,
           'status' => { 'name' => 'Open' },
           'feeFine' => { 'feeFineType' => 'Damaged material' },
           'actions' => [{ 'dateAction' => '2023-05-25T23:56:03.996+00:00', 'typeAction' => 'damage to material' }],
           'paymentStatus' => { 'name' => 'Outstanding' },
           'item' =>
           { 'id' => '020c1a15-3b9f-5b19-9b6f-d6e0f4351b85',
             'effectiveLocation' => { 'library' => { 'name' => 'Green Library' } },
             'barcode' => '36105228879115',
             'instance' => { 'title' => 'Memes and the future of pop culture / by Marcel Danesi',
                             'contributors' => [{ 'name' => 'Danesi, Marcel, 1946-' }] },
             'holdingsRecord' => { 'callNumber' => 'HM626 .D36 2019' } } }],
        'loans' => [{ 'id' => 'f4817e08-7118-44e1-a5ab-40fc30b29ff7',
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
                      'overdue' => true,
                      'details' =>
          { 'renewalCount' => nil,
            'dueDateChangedByRecall' => nil,
            'dueDateChangedByHold' => nil,
            'proxyUserId' => nil,
            'userId' => 'e705b594-1e94-4195-a4a3-fd50031cdacd',
            'status' => { 'name' => 'Open' },
            'feesAndFines' => { 'amountRemainingToPay' => 25 } } }],
        'totalCharges' => { 'isoCurrencyCode' => 'USD', 'amount' => 300 },
        'totalChargesCount' => 1,
        'totalLoans' => 0,
        'totalHolds' => 1 }.merge(custom_properties)
    end

    initialize_with { new(patron_graphql_response: patron_info) }
  end

  factory :undergraduate_patron, class: 'Folio::Patron' do
    transient do
      custom_properties { {} }
    end

    patron_info do
      { 'user' =>
        { 'username' => 'undergrad1',
          'id' => 'd7b67ab1-a3f2-45a9-87cc-d867bca8315f',
          'barcode' => 'undergrad1',
          'active' => true,
          'personal' => { 'email' => 'superuser1@stanford.edu', 'lastName' => 'Undergrad', 'firstName' => 'Ursula',
                          'preferredFirstName' => nil },
          'proxiesFor' => [],
          'proxiesOf' => [],
          'expirationDate' => nil,
          'externalSystemId' => nil,
          'patronGroup' =>
          { 'id' => 'bdc2b6d4-5ceb-4a12-ab46-249b9a68473e',
            'desc' => 'Undergraduate Student',
            'group' => 'undergrad',
            'limits' =>
            [{ 'conditionId' => 'cf7a0d5f-a327-4ca1-aa9e-dc55ec006b8a',
               'id' => '2b89bbe2-9324-43c1-a99b-a370877f74ad',
               'patronGroupId' => 'bdc2b6d4-5ceb-4a12-ab46-249b9a68473e',
               'value' => 50,
               'condition' =>
               { 'blockBorrowing' => true,
                 'blockRenewals' => true,
                 'blockRequests' => false,
                 'message' => 'You have fees and fines to pay. Your account is blocked.',
                 'name' => 'Maximum outstanding fee/fine balance',
                 'valueType' => 'Double' } },
             { 'conditionId' => 'e5b45031-a202-4abb-917b-e1df9346fe2c',
               'id' => '84b7fbff-4d5d-489b-a538-1cfd5fe8716b',
               'patronGroupId' => 'bdc2b6d4-5ceb-4a12-ab46-249b9a68473e',
               'value' => 2,
               'condition' =>
               { 'blockBorrowing' => true,
                 'blockRenewals' => false,
                 'blockRequests' => false,
                 'message' => 'You have recalled library materials that must be returned. Your account is blocked.',
                 'name' => 'Maximum number of overdue recalls',
                 'valueType' => 'Integer' } },
             { 'conditionId' => '08530ac4-07f2-48e6-9dda-a97bc2bf7053',
               'id' => '05f0b38e-471d-4de4-86c3-e1267e08670f',
               'patronGroupId' => 'bdc2b6d4-5ceb-4a12-ab46-249b9a68473e',
               'value' => 7,
               'condition' =>
               { 'blockBorrowing' => false,
                 'blockRenewals' => false,
                 'blockRequests' => false,
                 'message' => '',
                 'name' => 'Recall overdue by maximum number of days',
                 'valueType' => 'Integer' } }] },
          'blocks' => [{ 'message' => 'You have fees and fines to pay. Your account is blocked.' }],
          'manualBlocks' => [] },
        'id' => 'd7b67ab1-a3f2-45a9-87cc-d867bca8315f',
        'holds' =>
        [{ 'requestDate' => '2023-05-23T18:57:40.000+00:00',
           'item' =>
           { 'instanceId' => '10eb8fe0-2292-52a3-8e8b-cfa0c181d45a',
             'title' => 'Abstract and concrete categories : the joy of cats / Jiří Adámek, Horst Herrlich.',
             'itemId' => 'c9ac5271-2eb9-5243-a386-8e578b6b4c51',
             'item' =>
             { 'circulationNotes' => [],
               'effectiveShelvingOrder' => 'QA 3169 A3199 41990 11',
               'effectiveCallNumberComponents' => { 'callNumber' => 'QA169 .A3199 1990' },
               'effectiveLocation' => { 'code' => 'SAL3-STACKS', 'library' => { 'code' => 'SAL3' },
                                        'details' => { 'pageServicePoints' => [] } } },
             'author' => 'Adámek, Jiří, 1947-; Herrlich, Horst; Strecker, George E',
             'instance' => { 'hrid' => 'a1387091' },
             'isbn' => nil },
           'requestId' => '3a328071-ecf9-40c8-b726-43a5f24adb24',
           'status' => 'Open___In_transit',
           'expirationDate' => '2023-09-22T06:59:59.000+00:00',
           'details' => { 'holdShelfExpirationDate' => nil, 'proxyUserId' => nil, 'proxy' => nil },
           'pickupLocationId' => '67552bac-7644-4b5d-a973-045b8370f6e6',
           'pickupLocation' => { 'code' => 'HILA' },
           'queueTotalLength' => 1,
           'queuePosition' => 1,
           'cancellationReasonId' => nil,
           'canceledByUserId' => nil,
           'cancellationAdditionalInformation' => nil,
           'canceledDate' => nil,
           'patronComments' => nil },
         { 'requestDate' => '2023-06-09T02:13:01.000+00:00',
           'item' =>
           { 'instanceId' => '55ca51c2-88f8-48a0-91ef-69d38360003c',
             'title' =>
             'SW fixture - DO NOT EDIT Mastering hand building : techniques, tips, and tricks for slabs',
             'itemId' => nil,
             'item' => nil,
             'author' => 'Cobb, Sunshine,; Gill, Andrea, 1948-',
             'instance' => { 'hrid' => 'in00000056603' },
             'isbn' => nil },
           'requestId' => 'e9aa7330-12d1-406c-85f5-68e548bf2c50',
           'status' => 'Open___Not_yet_filled',
           'expirationDate' => nil,
           'details' => { 'holdShelfExpirationDate' => nil, 'proxyUserId' => nil, 'proxy' => nil },
           'pickupLocationId' => '77cd12ac-2de8-4d13-99a0-f6b3b4f4bdca',
           'pickupLocation' => { 'code' => 'ART' },
           'queueTotalLength' => 1,
           'queuePosition' => 1,
           'cancellationReasonId' => nil,
           'canceledByUserId' => nil,
           'cancellationAdditionalInformation' => nil,
           'canceledDate' => nil,
           'patronComments' => nil },
         { 'requestDate' => '2023-06-16T15:40:47.000+00:00',
           'item' =>
           { 'instanceId' => '55813e8f-9196-56db-8479-06393afff96f',
             'title' => 'The ash and the oak and the wild cherry tree / Kerry Hardie.',
             'itemId' => 'c4001473-48c8-5946-8861-163cddc0b3df',
             'item' =>
             { 'circulationNotes' => [],
               'effectiveShelvingOrder' => 'PR 46058 A622 A84 42012 11',
               'effectiveCallNumberComponents' => { 'callNumber' => 'PR6058 .A622 A84 2012' },
               'effectiveLocation' => { 'code' => 'SAL3-STACKS', 'library' => { 'code' => 'SAL3' },
                                        'details' => { 'pageServicePoints' => [] } } },
             'author' => 'Hardie, Kerry, 1951-',
             'instance' => { 'hrid' => 'a12185151' },
             'isbn' => nil },
           'requestId' => '1af5b593-1e6b-4ee8-a192-16fbc94348c2',
           'status' => 'Open___Not_yet_filled',
           'expirationDate' => nil,
           'details' => { 'holdShelfExpirationDate' => nil, 'proxyUserId' => nil, 'proxy' => nil },
           'pickupLocationId' => '77cd12ac-2de8-4d13-99a0-f6b3b4f4bdca',
           'pickupLocation' => { 'code' => 'ART' },
           'queueTotalLength' => 0,
           'queuePosition' => 1,
           'cancellationReasonId' => nil,
           'canceledByUserId' => nil,
           'cancellationAdditionalInformation' => nil,
           'canceledDate' => nil,
           'patronComments' => nil }],
        'accounts' =>
        [{ 'id' => '10990a47-c142-423d-987f-79352901cea2',
           'userId' => 'd7b67ab1-a3f2-45a9-87cc-d867bca8315f',
           'remaining' => 0,
           'amount' => 25,
           'loanId' => nil,
           'loan' => nil,
           'status' => { 'name' => 'Closed' },
           'feeFine' => { 'feeFineType' => 'Short term fine' },
           'actions' =>
           [{ 'dateAction' => '2023-07-19T19:15:44.916+00:00', 'typeAction' => 'Short term fine' },
            { 'dateAction' => '2023-07-19T19:16:11.402+00:00', 'typeAction' => 'Paid fully' }],
           'paymentStatus' => { 'name' => 'Paid fully' },
           'item' => nil },
         { 'id' => 'ca51f20a-8bb8-416e-bad1-c5c503513325',
           'userId' => 'd7b67ab1-a3f2-45a9-87cc-d867bca8315f',
           'remaining' => 0,
           'amount' => 100,
           'loanId' => nil,
           'loan' => nil,
           'status' => { 'name' => 'Closed' },
           'feeFine' => { 'feeFineType' => 'Lost item' },
           'actions' =>
           [{ 'dateAction' => '2023-07-19T19:20:40.022+00:00', 'typeAction' => 'Lost item' },
            { 'dateAction' => '2023-07-19T19:20:48.323+00:00', 'typeAction' => 'Paid fully' }],
           'paymentStatus' => { 'name' => 'Paid fully' },
           'item' =>
           { 'id' => '030223dc-ceef-569b-ad54-51b1588161a8',
             'effectiveLocation' => { 'library' => { 'name' => 'Green Library' } },
             'instance' =>
             { 'title' => "Charlie Brown's America : the popular politics of Peanuts / Blake Scott Ball",
               'contributors' => [{ 'name' => 'Ball, Blake Scott' }] },
             'holdingsRecord' => { 'callNumber' => 'PN6727 .S3 Z624 2021' } } },
         { 'id' => '4a00ff2c-8a03-4614-8430-e350e8195642',
           'userId' => 'd7b67ab1-a3f2-45a9-87cc-d867bca8315f',
           'remaining' => 0,
           'amount' => 25,
           'loanId' => nil,
           'loan' => nil,
           'status' => { 'name' => 'Closed' },
           'feeFine' => { 'feeFineType' => 'Manual Replacement Fee' },
           'actions' =>
           [{ 'dateAction' => '2023-07-18T00:06:51.538+00:00', 'typeAction' => 'Manual Replacement Fee' },
            { 'dateAction' => '2023-07-18T00:07:19.517+00:00', 'typeAction' => 'Paid partially' },
            { 'dateAction' => '2023-07-19T22:08:37.872+00:00', 'typeAction' => 'Waived fully' }],
           'paymentStatus' => { 'name' => 'Waived fully' },
           'item' =>
           { 'id' => '869fbec0-e14e-5ee8-a3cf-aad26d246942',
             'effectiveLocation' => { 'library' => { 'name' => 'SAL3 (off-campus storage)' } },
             'instance' =>
             { 'title' => '"Star shining on the mountain" [sound recording] : music of Medieval and Renaissance Spain.',
               'contributors' => [{ 'name' => 'Trio Live Oak' }] },
             'holdingsRecord' => { 'callNumber' => 'MD 7520' } } },
         { 'id' => 'f6b6645e-1a5d-4a2f-922c-830af223c899',
           'userId' => 'd7b67ab1-a3f2-45a9-87cc-d867bca8315f',
           'remaining' => 0,
           'amount' => 25,
           'loanId' => nil,
           'loan' => nil,
           'status' => { 'name' => 'Closed' },
           'feeFine' => { 'feeFineType' => 'SUL lost key' },
           'actions' =>
           [{ 'dateAction' => '2023-07-19T19:13:03.027+00:00', 'typeAction' => 'SUL lost key' },
            { 'dateAction' => '2023-07-19T19:13:15.238+00:00', 'typeAction' => 'Paid fully' }],
           'paymentStatus' => { 'name' => 'Paid fully' },
           'item' => nil },
         { 'id' => '0bebd1e3-c6a5-44e2-90a6-01f496e3d540',
           'userId' => 'd7b67ab1-a3f2-45a9-87cc-d867bca8315f',
           'remaining' => 0,
           'amount' => 75,
           'loanId' => nil,
           'loan' => nil,
           'status' => { 'name' => 'Closed' },
           'feeFine' => { 'feeFineType' => 'Damaged material' },
           'actions' =>
           [{ 'dateAction' => '2023-07-19T19:13:44.946+00:00', 'typeAction' => 'Damaged material' },
            { 'dateAction' => '2023-07-19T19:14:19.449+00:00', 'typeAction' => 'Waived fully' }],
           'paymentStatus' => { 'name' => 'Waived fully' },
           'item' => nil },
         { 'id' => 'c0e94bc2-1aed-410d-811a-c0de8b10e800',
           'userId' => 'd7b67ab1-a3f2-45a9-87cc-d867bca8315f',
           'remaining' => 0,
           'amount' => 75,
           'loanId' => '0ee4cfb0-e8ec-4282-913f-3a0bfb4b4c0f',
           'loan' => { 'proxyUserId' => nil },
           'status' => { 'name' => 'Closed' },
           'feeFine' => { 'feeFineType' => 'Lost item fee' },
           'actions' =>
           [{ 'dateAction' => '2023-07-08T10:32:29.191+00:00', 'typeAction' => 'Lost item fee' },
            { 'dateAction' => '2023-07-24T22:30:00.880+00:00', 'typeAction' => 'Paid fully' }],
           'paymentStatus' => { 'name' => 'Paid fully' },
           'item' =>
           { 'id' => 'e3df34c4-8b82-547f-8b23-5c4ebb3923b0',
             'effectiveLocation' => { 'library' => { 'name' => 'Green Library' } },
             'instance' => { 'title' => 'Alias the cat! / Kim Deitch.',
                             'contributors' => [{ 'name' => 'Deitch, Kim, 1944-' }] },
             'holdingsRecord' => { 'callNumber' => 'PN6727 .D383 A45 2007' } } },
         { 'id' => '1bd1c480-8c65-44a4-8024-dd87806661a4',
           'userId' => 'd7b67ab1-a3f2-45a9-87cc-d867bca8315f',
           'remaining' => 0,
           'amount' => 230,
           'loanId' => 'f4234e27-a56a-45a8-97a3-d7bb35783ffb',
           'loan' => { 'proxyUserId' => nil },
           'status' => { 'name' => 'Closed' },
           'feeFine' => { 'feeFineType' => 'Lost item fee' },
           'actions' =>
           [{ 'dateAction' => '2023-07-24T19:01:24.444+00:00', 'typeAction' => 'Lost item fee' },
            { 'dateAction' => '2023-07-24T22:30:00.880+00:00', 'typeAction' => 'Paid fully' }],
           'paymentStatus' => { 'name' => 'Paid fully' },
           'item' =>
           { 'id' => '869fbec0-e14e-5ee8-a3cf-aad26d246942',
             'effectiveLocation' => { 'library' => { 'name' => 'SAL3 (off-campus storage)' } },
             'instance' =>
             { 'title' => '"Star shining on the mountain" [sound recording] : music of Medieval and Renaissance Spain.',
               'contributors' => [{ 'name' => 'Trio Live Oak' }] },
             'holdingsRecord' => { 'callNumber' => 'MD 7520' } } },
         { 'id' => 'd412c6ec-b386-48b2-8f33-0c638307b269',
           'userId' => 'd7b67ab1-a3f2-45a9-87cc-d867bca8315f',
           'remaining' => 0,
           'amount' => 75,
           'loanId' => '31d15973-acb6-4a12-92c7-5e2d5f2470ed',
           'loan' => { 'proxyUserId' => nil },
           'status' => { 'name' => 'Closed' },
           'feeFine' => { 'feeFineType' => 'Lost item fee' },
           'actions' =>
           [{ 'dateAction' => '2023-07-24T19:10:58.877+00:00', 'typeAction' => 'Lost item fee' },
            { 'dateAction' => '2023-07-24T22:30:00.880+00:00', 'typeAction' => 'Paid fully' }],
           'paymentStatus' => { 'name' => 'Paid fully' },
           'item' =>
           { 'id' => 'f04011ac-e500-5208-8096-261ec5704cb2',
             'effectiveLocation' => { 'library' => { 'name' => 'SAL3 (off-campus storage)' } },
             'instance' =>
             { 'title' =>
               'Mental growth during the first three years; a developmental study of sixty-one children',
               'contributors' => [{ 'name' => 'Bayley, Nancy, 1899-1994' }] },
             'holdingsRecord' => { 'callNumber' => 'BF1 .G35' } } },
         { 'id' => '7e9730cb-9c74-4c48-a355-60c1fd8c8ee4',
           'userId' => 'd7b67ab1-a3f2-45a9-87cc-d867bca8315f',
           'remaining' => 0,
           'amount' => 75,
           'loanId' => '0647a116-2fdf-4050-a5eb-6ec3302438ea',
           'loan' => { 'proxyUserId' => nil },
           'status' => { 'name' => 'Closed' },
           'feeFine' => { 'feeFineType' => 'Lost item fee' },
           'actions' =>
           [{ 'dateAction' => '2023-07-08T10:32:29.605+00:00', 'typeAction' => 'Lost item fee' },
            { 'dateAction' => '2023-07-24T22:30:00.880+00:00', 'typeAction' => 'Paid fully' }],
           'paymentStatus' => { 'name' => 'Paid fully' },
           'item' =>
           { 'id' => 'ce9f62d8-57c5-5eec-8aa0-068d17e0c690',
             'effectiveLocation' => { 'library' => { 'name' => 'Green Library' } },
             'instance' => { 'title' => 'The archetypal cat / Patricial Dale-Green.',
                             'contributors' => [{ 'name' => 'Dale-Green, Patricia' }] },
             'holdingsRecord' => { 'callNumber' => 'GR725 .D29 1987' } } },
         { 'id' => 'f93d39be-d252-4c50-9201-193699dcdf8c',
           'userId' => 'd7b67ab1-a3f2-45a9-87cc-d867bca8315f',
           'remaining' => 0,
           'amount' => 75,
           'loanId' => 'e52a025c-2d73-4f95-a26e-7c82f9cc3832',
           'loan' => { 'proxyUserId' => nil },
           'status' => { 'name' => 'Closed' },
           'feeFine' => { 'feeFineType' => 'Lost item fee' },
           'actions' =>
           [{ 'dateAction' => '2023-07-24T19:10:59.101+00:00', 'typeAction' => 'Lost item fee' },
            { 'dateAction' => '2023-07-24T22:31:23.744+00:00', 'typeAction' => 'Paid fully' }],
           'paymentStatus' => { 'name' => 'Paid fully' },
           'item' =>
           { 'id' => 'c4377876-4d30-5505-91b3-78a764444d0c',
             'effectiveLocation' => { 'library' => { 'name' => 'SAL3 (off-campus storage)' } },
             'instance' =>
             { 'title' =>
               'Aspects of twentieth century art : Picasso - Important paintings, watercolours, and new linocuts.',
               'contributors' => [{ 'name' => 'Marlborough Fine Art Ltd' }] },
             'holdingsRecord' => { 'callNumber' => 'N6490 .M325' } } },
         { 'id' => '6fe14d1d-1497-4077-aa16-f4f11b746a75',
           'userId' => 'd7b67ab1-a3f2-45a9-87cc-d867bca8315f',
           'remaining' => 200,
           'amount' => 200,
           'loanId' => 'f34e39a4-e6eb-4785-ab6d-d04627352577',
           'loan' => { 'proxyUserId' => nil },
           'status' => { 'name' => 'Open' },
           'feeFine' => { 'feeFineType' => 'Lost item fee' },
           'actions' => [{ 'dateAction' => '2023-08-24T07:52:00.730+00:00', 'typeAction' => 'Lost item fee' }],
           'paymentStatus' => { 'name' => 'Outstanding' },
           'item' =>
           { 'id' => '5dfa4b14-f4ae-5bc8-b491-09919dd171c2',
             'effectiveLocation' => { 'library' => { 'name' => 'SUL' } },
             'instance' =>
             { 'title' =>
               '(RE)DISCOVERING THE OLMEC - NATIONAL GEOGRAPHIC SOCIETY-SMITHSONIAN INSTITUTION',
               'contributors' => [{ 'name' => 'LYON ROSEMARY DURKIN' }] },
             'holdingsRecord' => { 'callNumber' => 'F1219.1.V47 L96 1997' } } }],
        'loans' =>
        [{ 'id' => 'f34e39a4-e6eb-4785-ab6d-d04627352577',
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
             'feesAndFines' => { 'amountRemainingToPay' => 200 } } }],
        'totalCharges' => { 'isoCurrencyCode' => 'USD', 'amount' => 200 },
        'totalChargesCount' => 1,
        'totalLoans' => 1,
        'totalHolds' => 3 }.merge(custom_properties)
    end

    initialize_with { new(patron_graphql_response: patron_info) }
  end
end

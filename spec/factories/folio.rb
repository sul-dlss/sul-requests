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

    loan_policy { nil }

    initialize_with { new(record, nil, **attributes.except(:record)) }
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :grad_mono_loans, class: 'Folio::LoanPolicy' do
    loan_policy do
      { 'id' => '885a2bd0-35c7-497f-9dc6-462bebe837a3',
        'name' => '1qtr-3renew-7daygrace',
        'description' => 'Loan policy for monos owned by SUL, GSB and Law loaned to grad students',
        'renewable' => true,
        'renewalsPolicy' =>
         { 'numberAllowed' => 3, 'alternateFixedDueDateSchedule' => nil, 'period' => nil, 'renewFromId' => nil,
           'unlimited' => false },
        'loanable' => true,
        'loansPolicy' =>
         { 'period' => nil,
           'fixedDueDateSchedule' =>
           { 'schedules' =>
             [{ 'due' => '2023-04-04T06:59:59.000+00:00',
                'from' => '1993-02-01T08:00:00.000+00:00',
                'to' => '2023-02-25T07:59:59.000+00:00' },
              { 'due' => '2023-06-27T06:59:59.000+00:00',
                'from' => '2023-02-25T08:00:00.000+00:00',
                'to' => '2023-05-13T06:59:59.000+00:00' },
              { 'due' => '2023-09-27T06:59:59.000+00:00',
                'from' => '2023-05-13T07:00:00.000+00:00',
                'to' => '2023-08-15T06:59:59.000+00:00' },
              { 'due' => '2024-01-09T07:59:59.000+00:00',
                'from' => '2023-08-15T07:00:00.000+00:00',
                'to' => '2023-11-28T07:59:59.000+00:00' }] } },
        'requestManagement' => { 'holds' => { 'renewItemsWithRequest' => false } } }
    end

    initialize_with do
      new(loan_policy:)
    end
  end

  factory :reserves_loan_policy, class: 'Folio::LoanPolicy' do
    transient do
      due_date { '2024-01-09T07:59:59.000+00:00' }
      renewal_count { 0 }
      hold_queue_length { 0 }
    end

    loan_policy do
      { 'id' => '07115e75-c4a9-4ef0-b013-dba184251041',
        'name' => '7day-norenew-1daygrace',
        'description' => '7-day loan (Art periodicals and Business Permanent Reserves)',
        'renewable' => false,
        'renewalsPolicy' => nil,
        'loanable' => true,
        'loansPolicy' =>
  { 'period' => { 'duration' => 7, 'intervalId' => 'Days' }, 'fixedDueDateSchedule' => nil },
        'requestManagement' => { 'holds' => nil } }
    end

    initialize_with do
      new(loan_policy:)
    end
  end

  factory :overdue_fine_policy_daily, class: 'Hash' do
    overdue_fine_policy do
      Folio::Types.policies[:overdue].fetch('12d0d55b-bcb9-473e-9bd7-1a54d52c007f')
    end

    initialize_with do
      overdue_fine_policy
    end
  end
end

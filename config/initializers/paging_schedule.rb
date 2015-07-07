PagingSchedule.configure do
  # SAL3
  when_paging from: 'SAL3', to: 'GREEN', before: '12:00pm' do
    will_arrive after: '10:00am'
    business_days_later 1
  end
  when_paging from: 'SAL3', to: 'GREEN', after: '12:00pm' do
    will_arrive after: '10:00am'
    business_days_later 2
  end
  when_paging from: 'SAL3', to: :anywhere, before: '12:00pm' do
    will_arrive after: '4:00pm'
    business_days_later 1
  end
  when_paging from: 'SAL3', to: :anywhere, after: '12:00pm' do
    will_arrive after: '4:00pm'
    business_days_later 2
  end

  # SAL Newark
  when_paging from: 'SAL-NEWARK', to: 'GREEN', before: '10:00am' do
    will_arrive after: '4:30pm'
    business_days_later 1
  end
  when_paging from: 'SAL-NEWARK', to: 'GREEN', after: '10:00am' do
    will_arrive after: '4:30pm'
    business_days_later 2
  end
  when_paging from: 'SAL-NEWARK', to: :anywhere, before: '10:00am' do
    will_arrive after: '4:30pm'
    business_days_later 2
  end
  when_paging from: 'SAL-NEWARK', to: :anywhere, after: '10:00am' do
    will_arrive after: '4:30pm'
    business_days_later 3
  end

  # SAL 1/2
  when_paging from: 'SAL', to: 'GREEN', before: '1:00pm' do
    will_arrive after: '4:30pm'
    business_days_later 0
  end
  when_paging from: 'SAL', to: 'GREEN', after: '1:00pm' do
    will_arrive after: '1:00pm'
    business_days_later 1
  end
  when_paging from: 'SAL', to: :anywhere, before: '1:00pm' do
    will_arrive after: '4:30pm'
    business_days_later 1
  end
  when_paging from: 'SAL', to: :anywhere, after: '1:00pm' do
    will_arrive after: '4:30pm'
    business_days_later 2
  end

  # Hopkins
  when_paging from: 'HOPKINS', to: 'GREEN', before: '9:00am' do
    will_arrive after: '12:00pm'
    business_days_later 1
  end
  # This is not in the table.
  when_paging from: 'HOPKINS', to: 'GREEN', after: '9:00am' do
    will_arrive after: '12:00pm'
    business_days_later 2
  end
  when_paging from: 'HOPKINS', to: :anywhere, before: '9:00am' do
    will_arrive after: '12:00pm'
    business_days_later 2
  end
  # This is not in the table.
  when_paging from: 'HOPKINS', to: :anywhere, after: '9:00am' do
    will_arrive after: '12:00pm'
    business_days_later 3
  end

  # Hoover Archive
  when_paging from: 'HV-ARCHIVE', to: 'HV-ARCHIVE', before: '10:00am' do
    will_arrive after: '11:00am'
    business_days_later 1
  end
  when_paging from: 'HV-ARCHIVE', to: 'HV-ARCHIVE', after: '10:00am' do
    will_arrive after: '11:00am'
    business_days_later 2
  end

  # Hoover
  when_paging from: 'HOOVER', to: 'HOOVER', before: '10:00am' do
    will_arrive after: '11:00am'
    business_days_later 1
  end
  when_paging from: 'HOOVER', to: 'HOOVER', after: '10:00am' do
    will_arrive after: '11:00am'
    business_days_later 2
  end

  # Special Collections
  when_paging from: 'SPEC-COLL', to: 'SPEC-COLL', before: '10:00am' do
    will_arrive after: '11:00am'
    business_days_later 1
  end
  when_paging from: 'SPEC-COLL', to: 'SPEC-COLL', after: '10:00am' do
    will_arrive after: '11:00am'
    business_days_later 2
  end
end

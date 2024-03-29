Rails.application.config.after_initialize do
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
    # Scan (based on SAL3 -> GREEN with added days)
    when_paging from: 'SAL3', to: 'SCAN', before: '11:55am' do
      will_arrive after: '3:00pm'
      business_days_later 1
    end
    when_paging from: 'SAL3', to: 'SCAN', after: '11:55am' do
      will_arrive after: '12:00pm'
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
    when_paging from: 'SAL', to: 'SCAN', before: '1:00pm' do
      will_arrive after: '6:00pm'
      business_days_later 1
    end
    when_paging from: 'SAL', to: 'SCAN', after: '1:00pm' do
      will_arrive after: '6:00pm'
      business_days_later 2
    end
    when_paging from: 'SAL', to: :anywhere, before: '1:00pm' do
      will_arrive after: '4:30pm'
      business_days_later 1
    end
    when_paging from: 'SAL', to: :anywhere, after: '1:00pm' do
      will_arrive after: '4:30pm'
      business_days_later 2
    end

    # Education (at SAL 1/2)
    when_paging from: 'EDUCATION', to: 'GREEN', before: '1:00pm' do
      will_arrive after: '4:30pm'
      business_days_later 0
    end
    when_paging from: 'EDUCATION', to: 'GREEN', after: '1:00pm' do
      will_arrive after: '1:00pm'
      business_days_later 1
    end
    when_paging from: 'EDUCATION', to: 'SCAN', before: '1:00pm' do
      will_arrive after: '6:00pm'
      business_days_later 1
    end
    when_paging from: 'EDUCATION', to: 'SCAN', after: '1:00pm' do
      will_arrive after: '6:00pm'
      business_days_later 2
    end
    when_paging from: 'EDUCATION', to: :anywhere, before: '1:00pm' do
      will_arrive after: '4:30pm'
      business_days_later 1
    end
    when_paging from: 'EDUCATION', to: :anywhere, after: '1:00pm' do
      will_arrive after: '4:30pm'
      business_days_later 2
    end

    # Hopkins
    when_paging from: 'MARINE-BIO', to: 'GREEN', before: '9:00am' do
      will_arrive after: '12:00pm'
      business_days_later 1
    end
    # This is not in the table.
    when_paging from: 'MARINE-BIO', to: 'GREEN', after: '9:00am' do
      will_arrive after: '12:00pm'
      business_days_later 2
    end
    when_paging from: 'MARINE-BIO', to: :anywhere, before: '9:00am' do
      will_arrive after: '12:00pm'
      business_days_later 2
    end
    # This is not in the table.
    when_paging from: 'MARINE-BIO', to: :anywhere, after: '9:00am' do
      will_arrive after: '12:00pm'
      business_days_later 3
    end

    # Special Collections
    when_paging from: 'SPEC-COLL', to: 'SPEC-COLL', before: '10:00am' do
      will_arrive after: '9:00am'
      business_days_later 1
    end
    when_paging from: 'SPEC-COLL', to: 'SPEC-COLL', after: '10:00am' do
      will_arrive after: '9:00am'
      business_days_later 2
    end

    # Business (PAGE-IRON). This location can only be paged to BUSINESS
    when_paging from: 'BUSINESS', to: 'BUSINESS', before: '12:00pm' do
      will_arrive after: '3:00pm'
      business_days_later 1
    end
    when_paging from: 'BUSINESS', to: 'BUSINESS', after: '12:00pm' do
      will_arrive after: '3:00pm'
      business_days_later 2
    end

    # Rumsey Map Center
    when_paging from: 'RUMSEY-MAP', to: :anywhere, before: '12:00pm' do
      will_arrive after: '1:00pm'
      business_days_later 3
    end
    when_paging from: 'RUMSEY-MAP', to: :anywhere, after: '12:00pm' do
      will_arrive after: '1:00pm'
      business_days_later 3
    end

    # Media Microtext
    when_paging from: 'MEDIA-CENTER', to: 'MEDIA-CENTER', before: '10:00am' do
      will_arrive after: '11:00am'
      business_days_later 0
    end
    when_paging from: 'MEDIA-CENTER', to: 'MEDIA-CENTER', before: '2:00pm' do
      will_arrive after: '3:00pm'
      business_days_later 0
    end
    when_paging from: 'MEDIA-CENTER', to: 'MEDIA-CENTER', before: '5:00pm' do
      will_arrive after: '6:00pm'
      business_days_later 0
    end
    when_paging from: 'MEDIA-CENTER', to: 'MEDIA-CENTER', after: '5:00pm' do
      will_arrive after: '11:00am'
      business_days_later 1
    end

    when_paging from: 'MEDIA-CENTER', to: 'GREEN', before: '10:00am' do
      will_arrive after: '11:00am'
      business_days_later 0
    end
    when_paging from: 'MEDIA-CENTER', to: 'GREEN', before: '2:00pm' do
      will_arrive after: '3:00pm'
      business_days_later 0
    end
    when_paging from: 'MEDIA-CENTER', to: 'GREEN', before: '6:30pm' do
      will_arrive after: '7:30pm'
      business_days_later 0
    end
    when_paging from: 'MEDIA-CENTER', to: 'GREEN', after: '6:30pm' do
      will_arrive after: '11:00am'
      business_days_later 1
    end

    when_paging from: 'MEDIA-CENTER', to: 'MARINE-BIO', before: '10:00am' do
      will_arrive after: '1:00pm'
      business_days_later 1
    end
    when_paging from: 'MEDIA-CENTER', to: 'MARINE-BIO', after: '10:00am' do
      will_arrive after: '1:00pm'
      business_days_later 2
    end

    when_paging from: 'MEDIA-CENTER', to: :anywhere, before: '3:00pm' do
      will_arrive after: '12:00pm'
      business_days_later 1
    end
    when_paging from: 'MEDIA-CENTER', to: :anywhere, after: '3:00pm' do
      will_arrive after: '12:00pm'
      business_days_later 2
    end

    when_paging from: 'ART', to: 'ART', before: '12:00pm' do
      will_arrive after: '2:00pm'
      business_days_later 0
    end
    when_paging from: 'ART', to: 'ART', after: '12:00pm' do
      will_arrive after: '10:00am'
      business_days_later 1
    end

    # Lane Medical Library
    when_paging from: 'LANE', to: 'LANE', before: '9:00am' do
      will_arrive after: '3:00pm'
      business_days_later 0
    end
    when_paging from: 'LANE', to: 'LANE', after: '9:00am' do
      will_arrive after: '3:00pm'
      business_days_later 1
    end
    when_paging from: 'LANE', to: 'LANE-DESK', before: '9:00am' do
      will_arrive after: '3:00pm'
      business_days_later 0
    end
    when_paging from: 'LANE', to: 'LANE-DESK', after: '9:00am' do
      will_arrive after: '3:00pm'
      business_days_later 1
    end
    when_paging from: 'LANE', to: :anywhere, before: '9:00am' do
      will_arrive after: '3:00pm'
      business_days_later 1
    end
    when_paging from: 'LANE', to: :anywhere, after: '9:00am' do
      will_arrive after: '3:00pm'
      business_days_later 2
    end
  end
end

FactoryGirl.define do
  factory :mediated_page do
    item_id '1234'
    origin 'SPEC-COLL'
    origin_location 'STACKS'
    destination 'SPEC-COLL'
    item_title 'Title of MediatedPage 1234'
    needed_date Time.zone.today

    after(:build) do |request|
      class << request
        def needed_date_is_valid; end
      end
    end
  end

  factory :page_mp_mediated_page, class: MediatedPage do
    item_id '1234'
    origin 'SAL3'
    origin_location 'PAGE-MP'
    destination 'EARTH-SCI'
    item_title 'Title of MediatedPage 1234'
    needed_date Time.zone.today
  end

  factory :hopkins_mediated_page, class: MediatedPage do
    item_id '1234'
    origin 'HOPKINS'
    origin_location 'STACKS'
    destination 'GREEN'
    item_title 'Title of MediatedPage 1234'
    needed_date Time.zone.today
  end

  factory :hoover_mediated_page, parent: :mediated_page do
    origin 'HOOVER'
    origin_location 'SOMEWHERE-30'
    destination 'HOOVER'
  end

  factory :hoover_archive_mediated_page, parent: :mediated_page do
    origin 'HV-ARCHIVE'
    origin_location 'SOMEWHERE-30'
    destination 'HV-ARCHIVE'
  end

  factory :mediated_page_with_holdings, parent: :mediated_page do
    item_id '1234'
    origin 'SPEC-COLL'
    origin_location 'STACKS'
    destination 'SPEC-COLL'
    needed_date Time.zone.today

    after(:build) do |request|
      class << request
        def searchworks_item
          @searchworks_item ||= FactoryGirl.build(:spec_coll_stacks_multi_holdings_searchworks_item, request: self)
        end
      end
    end
  end
end

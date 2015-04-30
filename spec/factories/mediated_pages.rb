FactoryGirl.define do
  factory :mediated_page do
    item_id '1234'
    origin 'SPEC-COLL'
    origin_location 'STACKS'
    item_title 'Title of MediatedPage 1234'
  end

  factory :page_mp_mediated_page, class: MediatedPage do
    item_id '1234'
    origin 'SAL3'
    origin_location 'PAGE-MP'
    item_title 'Title of MediatedPage 1234'
  end

  factory :hopkins_mediated_page, class: MediatedPage do
    item_id '1234'
    origin 'HOPKINS'
    origin_location 'STACKS'
    item_title 'Title of MediatedPage 1234'
  end

  factory :hoover_mediated_page, class: MediatedPage do
    item_id '1234'
    origin 'HOOVER'
    origin_location 'SOMEWHERE-30'
    item_title 'Title of MediatedPage 1234'
  end

  factory :hoover_archive_mediated_page, class: MediatedPage do
    item_id '1234'
    origin 'HV-ARCHIVE'
    origin_location 'SOMEWHERE-30'
    item_title 'Title of MediatedPage 1234'
  end
end

# frozen_string_literal: true

long_comment = <<-LONG
  It's wonderful to be here it's certainly a thrill you're such a lovely audience we'd love to take you home with us we'd love to take you home no really we'd really really love to take you home especially if you are a cute puppy.
LONG

FactoryBot.define do
  factory :mediated_page do
    item_id '1234'
    origin 'SPEC-COLL'
    origin_location 'STACKS'
    destination 'SPEC-COLL'
    item_title 'Title of MediatedPage 1234'
    needed_date Time.zone.today
    association :user, factory: :sequence_webauth_user

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
    association :user, factory: :sequence_webauth_user
  end

  factory :hopkins_mediated_page, class: MediatedPage do
    item_id '1234'
    origin 'HOPKINS'
    origin_location 'STACKS'
    destination 'GREEN'
    item_title 'Title of MediatedPage 1234'
    needed_date Time.zone.today
    association :user, factory: :sequence_webauth_user
  end

  factory :hoover_archive_mediated_page, parent: :mediated_page do
    origin 'HV-ARCHIVE'
    origin_location 'SOMEWHERE-30'
    destination 'HV-ARCHIVE'
    association :user, factory: :sequence_webauth_user
  end

  factory :mediated_page_with_single_holding, parent: :mediated_page do
    item_id '12345'
    origin 'SPEC-COLL'
    origin_location 'STACKS'
    destination 'SPEC-COLL'
    needed_date Time.zone.today
    request_comment long_comment
    association :user, factory: :sequence_webauth_user

    after(:build) do |request|
      class << request
        def symphony_response_data
          FactoryBot.build(:symphony_page_with_single_item)
        end
      end
    end
  end

  factory :mediated_page_with_holdings, parent: :mediated_page do
    item_id '1234'
    origin 'SPEC-COLL'
    origin_location 'STACKS'
    destination 'SPEC-COLL'
    needed_date Time.zone.today
    request_comment long_comment
    association :user, factory: :sequence_webauth_user

    after(:build) do |request|
      class << request
        def searchworks_item
          @searchworks_item ||= FactoryBot.build(:spec_coll_stacks_multi_holdings_searchworks_item, request: self)
        end
      end
    end
  end
end

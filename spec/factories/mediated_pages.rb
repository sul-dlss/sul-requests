# frozen_string_literal: true

long_comment = <<-LONG
  It's wonderful to be here it's certainly a thrill you're such a lovely audience we'd love to take you home with us we'd love to take you home no really we'd really really love to take you home especially if you are a cute puppy.
LONG

FactoryBot.define do
  factory :mediated_page do
    item_id { '1234' }
    origin { 'ART' }
    origin_location { 'ARTLCKL' }
    destination { 'ART' }
    item_title { 'Title of MediatedPage 1234' }
    needed_date { Time.zone.today }
    user factory: [:sequence_sso_user]

    after(:build) do |request|
      class << request
        def needed_date_is_valid; end
      end
    end
  end

  factory :page_mp_mediated_page, class: 'MediatedPage' do
    item_id { '1234' }
    origin { 'SAL3' }
    origin_location { 'PAGE-MP' }
    destination { 'EARTH-SCI' }
    item_title { 'Title of MediatedPage 1234' }
    needed_date { Time.zone.today }
    user factory: [:sequence_sso_user]
  end

  factory :mediated_page_with_single_holding, parent: :mediated_page do
    item_id { '12345' }
    origin { 'ART' }
    origin_location { 'ARTLCKL' }
    destination { 'ART' }
    needed_date { Time.zone.today }
    request_comment { long_comment }
    user factory: [:sequence_sso_user]

    after(:build) do |request|
      class << request
        def symphony_response_data
          FactoryBot.build(:symphony_page_with_single_item)
        end
      end
    end
  end

  factory :mediated_page_with_holdings, parent: :mediated_page do
    item_id { '1234' }
    origin { 'ART' }
    origin_location { 'ARTLCKL' }
    destination { 'ART' }
    needed_date { Time.zone.today }
    request_comment { long_comment }
    user factory: [:sequence_sso_user]

    after(:build) do |request|
      class << request
        def bib_data
          @bib_data ||= FactoryBot.build(:art_multi_holdings_searchworks_item, request: self)
        end
      end
    end
  end

  factory :mediated_page_with_symphony_errors, class: 'MediatedPage', parent: :request_with_symphony_errors do
    origin { 'ART' }
    origin_location { 'ARTLCKL' }
    destination { 'ART' }
    needed_date { Time.zone.today }
    user factory: [:sequence_sso_user]

    after(:build) do |request|
      class << request
        def needed_date_is_valid; end
      end
    end
  end
end

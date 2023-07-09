# frozen_string_literal: true

FactoryBot.define do
  factory :page do
    item_id { '1234' }
    origin { 'GREEN' }
    origin_location { 'STACKS' }
    destination { 'ART' }
    item_title { 'Title for Page 1234' }
    bib_data { Folio::Instance.new(id: '1234') } if Settings.ils.bib_model == 'Folio::Instance'

    after(:build) do |request|
      class << request
        def symphony_response_data
          FactoryBot.build(:symphony_page_with_single_item)
        end
      end
    end
  end

  factory :page_with_holdings, class: 'Page' do
    item_id { '1234' }
    origin { 'GREEN' }
    origin_location { 'STACKS' }
    destination { 'ART' }
    bib_data { FactoryBot.build(:multiple_holdings) }
  end
end

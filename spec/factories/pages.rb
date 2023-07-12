# frozen_string_literal: true

FactoryBot.define do
  factory :page do
    item_id { '1234' }
    origin { 'GREEN' }
    origin_location { 'STACKS' }
    destination { 'ART' }
    item_title { 'Title for Page 1234' }
    bib_data { build(:green_stacks_searchworks_item) }
    symphony_response_data { build(:symphony_page_with_single_item) }
  end

  factory :page_with_holdings, class: 'Page' do
    item_id { '1234' }
    origin { 'GREEN' }
    origin_location { 'STACKS' }
    destination { 'ART' }
    bib_data { build(:multiple_holdings) }
  end

  factory :page_on_order, class: 'Page' do
    item_id { '1234' }
    origin { 'ZOMBIE' }
    origin_location { 'STACKS' }
    destination { 'ART' }
    bib_data { build(:on_order_instance) }
  end
end

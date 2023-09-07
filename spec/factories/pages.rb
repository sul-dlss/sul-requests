# frozen_string_literal: true

FactoryBot.define do
  factory :page do
    item_id { '1234' }
    location { 'SAL3-STACKS' }
    destination { 'ART' }
    item_title { 'Title for Page 1234' }
    bib_data { build(:sal3_stacks_searchworks_item) }
    symphony_response_data { build(:symphony_page_with_single_item) }
  end

  factory :page_with_holdings, class: 'Page' do
    item_id { '1234' }
    location { 'SAL3-STACKS' }
    destination { 'ART' }
    bib_data { build(:multiple_holdings) }
  end

  factory :page_with_single_holding_multiple_items, class: 'Page' do
    item_id { '1234' }
    location { 'SAL3-STACKS' }
    destination { 'ART' }
    bib_data { build(:single_holding_multiple_items) }
  end
end

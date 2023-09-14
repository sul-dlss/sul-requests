# frozen_string_literal: true

FactoryBot.define do
  factory :scan do
    item_id { '12345' }
    origin { 'SAL3' }
    origin_location { 'STACKS' }
    section_title { 'Section Title for Scan 12345' }

    trait :with_item_title do
      item_title { 'Title for Scan 12345' }
    end

    trait :without_validations do
      to_create { |instance| instance.save(validate: false) }
    end

    trait :with_holdings do
      bib_data { FactoryBot.build(:scannable_holdings) }
    end

    trait :with_holdings_barcodes do
      with_holdings
      after(:build) do |scan|
        scan.barcodes = [scan.holdings.first.barcode, scan.holdings.to_a.last.barcode].uniq
      end
    end
  end
end

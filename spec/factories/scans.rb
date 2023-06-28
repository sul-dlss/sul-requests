# frozen_string_literal: true

FactoryBot.define do
  factory :scan do
    item_id { '12345' }
    origin { 'SAL' }
    origin_location { 'STACKS' }
    section_title { 'Section Title for Scan 12345' }

    trait :with_item_title do
      item_title { 'Title for Scan 12345' }
    end

    trait :without_validations do
      to_create { |instance| instance.save(validate: false) }
    end

    trait :with_holdings do
      after(:build) do |scan|
        class << scan
          def bib_data
            @bib_data ||= FactoryBot.build(:sal_stacks_multi_holdings_searchworks_item, request: self)
          end
        end
      end
    end

    trait :with_holdings_barcodes do
      with_holdings
      after(:build) do |scan|
        scan.barcodes = [scan.holdings.first.barcode, scan.holdings.last.barcode]
      end
    end
  end
end

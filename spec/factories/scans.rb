FactoryBot.define do
  factory :scan do
    item_id '12345'
    origin 'SAL3'
    origin_location 'STACKS'
    item_title 'Title for Scan 12345'
    section_title 'Section Title for Scan 12345'

    to_create { |instance| instance.save(validate: false) }
  end

  factory :scan_with_holdings, class: Scan do
    item_id '12345'
    origin 'SAL3'
    origin_location 'STACKS'
    section_title 'Section Title for Scan 12345'

    after(:build) do |scan|
      class << scan
        def searchworks_item
          @searchworks_item ||= FactoryBot.build(:sal3_stacks_multi_holdings_searchworks_item, request: self)
        end
      end
    end
  end

  factory :scan_with_holdings_barcodes, parent: :scan_with_holdings do
    after(:build) do |scan|
      scan.barcodes = [scan.holdings.first.barcode, scan.holdings.last.barcode]
    end
  end
end

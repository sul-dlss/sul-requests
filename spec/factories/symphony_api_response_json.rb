FactoryGirl.define do
  factory :symphony_scan_with_multiple_items, class: Hash do
    req_type 'SCAN'
    confirm_email 'jlathrop@stanford.edu'
    usererr_code 'U002'
    usererr_text 'Invalid user'
    requested_items [
      {
        'barcode' => '12345678901234',
        'msgcode' => '209',
        'text' => 'Hold placed'
      },
      {
        'barcode' => '12345678901234z',
        'msgcode' => '7',
        'text' => 'Item not found in catalog'
      },
      {
        'barcode' => '36105212920537',
        'msgcode' => 'S001',
        'text' => 'Scan submitted'
      }
    ]

    initialize_with do
      attributes.map do |k, h|
        [k.to_s, h]
      end.to_h
    end
  end
end

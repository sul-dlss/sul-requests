# frozen_string_literal: true

FactoryBot.define do
  factory :symphony_scan_success, class: Hash do
    req_type 'SCAN'
    confirm_email 'jlathrop@stanford.edu'
    requested_items [
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

  factory :symphony_scan_with_multiple_items, class: Hash do
    req_type 'SCAN'
    confirm_email 'jlathrop@stanford.edu'
    usererr_code 'U003'
    usererr_text 'Blocked user'
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

  factory :symphony_page_with_single_item, class: Hash do
    req_type 'PAGE'
    confirm_email 'jlathrop@stanford.edu'
    requested_items [
      {
        'barcode' => '3610512345',
        'msgcode' => '209',
        'text' => 'Hold placed'
      }
    ]

    initialize_with do
      attributes.map do |k, h|
        [k.to_s, h]
      end.to_h
    end
  end

  factory :symphony_page_with_multiple_items, class: Hash do
    req_type 'PAGE'
    confirm_email 'jlathrop@stanford.edu'
    requested_items [
      {
        'barcode' => '12345678',
        'msgcode' => '209',
        'text' => 'Hold placed'
      },
      {
        'barcode' => '23456789',
        'msgcode' => '209',
        'text' => 'Hold placed'
      }
    ]

    initialize_with do
      attributes.map do |k, h|
        [k.to_s, h]
      end.to_h
    end
  end

  factory :symphony_request_with_mixed_status, class: Hash do
    req_type 'PAGE'
    confirm_email 'jlathrop@stanford.edu'
    requested_items [
      {
        'barcode' => '12345678',
        'msgcode' => '209',
        'text' => 'Hold placed'
      },
      {
        'barcode' => '23456789',
        'msgcode' => '7',
        'text' => 'Item not found in catalog'
      }
    ]

    initialize_with do
      attributes.map do |k, h|
        [k.to_s, h]
      end.to_h
    end
  end

  factory :symphony_request_with_all_errored_items, class: Hash do
    req_type 'PAGE'
    confirm_email 'jlathrop@stanford.edu'
    requested_items [
      {
        'barcode' => '3610512345',
        'msgcode' => '123',
        'text' => 'Unknown error'
      },
      {
        'barcode' => '23456789',
        'msgcode' => '7',
        'text' => 'Item not found in catalog'
      }
    ]

    initialize_with do
      attributes.map do |k, h|
        [k.to_s, h]
      end.to_h
    end
  end

  factory :symphony_page_with_blocked_user, class: Hash do
    req_type 'PAGE'
    confirm_email 'jlathrop@stanford.edu'
    usererr_code 'U003'
    requested_items []

    initialize_with do
      attributes.map do |k, h|
        [k.to_s, h]
      end.to_h
    end
  end

  factory :symphony_page_with_expired_user, class: Hash do
    req_type 'PAGE'
    confirm_email 'jlathrop@stanford.edu'
    usererr_code 'U004'
    requested_items []

    initialize_with do
      attributes.map do |k, h|
        [k.to_s, h]
      end.to_h
    end
  end
end

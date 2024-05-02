# frozen_string_literal: true

FactoryBot.define do
  factory :patron, class: 'Folio::Patron' do
    id { 'some-uuid' }
    username { 'test ' }
    personal do
      {
        'firstName' => 'Test',
        'lastName' => 'User',
        'email' => 'test@example.com'
      }
    end
    patronGroup { '503a81cd-6c26-400f-b620-14c08943697c' }
    stubs do
      {
        patron_blocks: [],
        proxy_info: {},
        proxy_group_info: {},
        all_proxy_group_info: {}
      }
    end

    initialize_with do
      new(attributes.deep_stringify_keys)
    end
  end

  factory :library_id_patron, parent: :patron do
    id { 'some-lib-id-uuid' }
    patronGroup { '985acbb9-f7a7-4f44-9b34-458c02a78fbc' }
  end

  factory :blocked_patron, parent: :patron do
    stubs do
      {
        patron_blocks: [
          {
            patronBlockConditionId: 'ac13a725-b25f-48fa-84a6-4af021d13afe',
            blockBorrowing: false,
            blockRenewals: false,
            blockRequests: true,
            message: 'Patron has reached maximum allowed outstanding fee/fine balance for his/her patron group'
          }
        ],
        proxy_info: {},
        proxy_group_info: {},
        all_proxy_group_info: {}
      }
    end
  end
end

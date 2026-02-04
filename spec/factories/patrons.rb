# frozen_string_literal: true

FactoryBot.define do
  factory :patron, class: 'Folio::Patron' do
    id { 'some-uuid' }
    username { 'test ' }
    personal do
      {
        'firstName' => first_name,
        'lastName' => last_name,
        'email' => email
      }
    end
    patronGroup { '503a81cd-6c26-400f-b620-14c08943697c' }
    stubs do
      {
        patron_blocks: [],
        proxies: [],
        sponsors: [],
        patron_summary: { holds: [], loans: [] }
      }
    end

    initialize_with do
      new(attributes.deep_stringify_keys)
    end

    transient do
      first_name { 'Test' }
      last_name { 'User' }
      email { 'test@example.com' }
    end
  end

  factory :library_id_patron, parent: :patron do
    id { 'some-lib-id-uuid' }
    patronGroup { '985acbb9-f7a7-4f44-9b34-458c02a78fbc' }
  end

  factory :pilot_group_patron, parent: :patron do
    id { 'some-lib-id-uuid' }
    group = Folio::Types.patron_groups.find_by(group: Settings.folio.scan_pilot_groups.first)
    patronGroup { group.id }
  end

  factory :purchased_patron, parent: :patron do
    id { 'some-lib-id-uuid' }
    group = Folio::Types.patron_groups.find_by(group: 'sul-purchased')
    patronGroup { group.id }
  end

  factory :student_patron, parent: :patron do
    id { 'some-lib-id-uuid' }
    group = Folio::Types.patron_groups.find_by(group: 'undergrad')
    patronGroup { group.id }
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
        proxies: [],
        sponsors: [],
        patron_summary: { holds: [], loans: [] }
      }
    end
  end

  factory :expired_patron, parent: :patron do
    active { false }
  end

  factory :visitor_patron, class: 'Folio::NullPatron' do
    display_name { 'Visitor' }
    email { 'visitor@example.com' }

    initialize_with do
      new(**attributes)
    end
  end
end

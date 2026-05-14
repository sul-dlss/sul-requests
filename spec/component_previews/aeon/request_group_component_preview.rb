# frozen_string_literal: true

module Aeon
  class RequestGroupComponentPreview < ViewComponent::Preview
    layout 'lookbook'

    # @!group Submitted
    def submitted_single_appointment_request
      request_group = Aeon::RequestGrouping.new(
        [FactoryBot.build(:aeon_request, :submitted, call_number: 'XYZ 123')]
      )
      render Aeon::RequestGroupComponent.new(request_group:)
    end

    def submitted_multi_box_ead
      request_group = Aeon::RequestGrouping.new(
        [
          FactoryBot.build(:aeon_request, :submitted, :ead, call_number: 'Box 1'),
          FactoryBot.build(:aeon_request, :submitted, :ead, call_number: 'Box 2'),
          FactoryBot.build(:aeon_request, :submitted, :ead, call_number: 'Box 3')
        ]
      )
      render Aeon::RequestGroupComponent.new(request_group:)
    end

    def submitted_digitization
      request_group = Aeon::RequestGrouping.new(
        [
          FactoryBot.build(:aeon_request, :submitted, :digitized, :ead, call_number: 'Box 1', item_info5: '12-20'),
          FactoryBot.build(:aeon_request, :delivered, :digitized, :ead, call_number: 'Box 2', item_info5: '45-60')
        ]
      )
      render Aeon::RequestGroupComponent.new(request_group:)
    end

    def submitted_rumsey_appointment
      reading_room = FactoryBot.build(:aeon_reading_room, id: 7, name: 'David Rumsey Map Center', sites: ['RUMSEY'])
      appointment = FactoryBot.build(:aeon_appointment, reading_room_id: 7, reading_room:,
                                                        start_time: Time.zone.parse('2026-03-11T18:30:00Z'),
                                                        stop_time: Time.zone.parse('2026-03-11T19:30:00Z'))
      request = FactoryBot.build(:aeon_request, :submitted, appointment:,
                                                            item_title: 'Map of the city of San Francisco, 1872',
                                                            call_number: 'G3300 1872 .R3')
      render Aeon::RequestGroupComponent.new(request_group: Aeon::RequestGrouping.new([request]))
    end
    # @!endgroup

    # @!group Draft
    def draft_single_appointment_request
      request_group = Aeon::RequestGrouping.new(
        [FactoryBot.build(:aeon_request, :draft, call_number: 'XYZ 123')]
      )
      render Aeon::RequestGroupComponent.new(request_group:)
    end

    def draft_multi_box_ead
      request_group = Aeon::RequestGrouping.new(
        [
          FactoryBot.build(:aeon_request, :draft, :ead, call_number: 'Box 1'),
          FactoryBot.build(:aeon_request, :draft, :ead, call_number: 'Box 2'),
          FactoryBot.build(:aeon_request, :draft, :ead, call_number: 'Box 3')
        ]
      )
      render Aeon::RequestGroupComponent.new(request_group:)
    end

    def draft_digitization
      request_group = Aeon::RequestGrouping.new(
        [FactoryBot.build(:aeon_request, :draft, :digitized)]
      )
      render Aeon::RequestGroupComponent.new(request_group:)
    end
    # @!endgroup
  end
end

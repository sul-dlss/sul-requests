# frozen_string_literal: true

module Aeon
  class ReadingRoomBriefComponentPreview < ViewComponent::Preview
    layout 'lookbook'

    # @!group Variations
    def spec
      @reading_room = Aeon::ReadingRoom.find_by(site: 'SPECUA')

      render Aeon::ReadingRoomBriefComponent.new(reading_room: @reading_room, create_appointment: true)
    end

    def rumsey
      @reading_room = Aeon::ReadingRoom.find_by(site: 'RUMSEY')

      render Aeon::ReadingRoomBriefComponent.new(reading_room: @reading_room, create_appointment: true)
    end

    def eal
      @reading_room = Aeon::ReadingRoom.find_by(site: 'EASTASIA')

      render Aeon::ReadingRoomBriefComponent.new(reading_room: @reading_room, create_appointment: true)
    end

    def ars
      @reading_room = Aeon::ReadingRoom.find_by(site: 'ARS')

      render Aeon::ReadingRoomBriefComponent.new(reading_room: @reading_room, create_appointment: true)
    end
    # @!endgroup
  end
end

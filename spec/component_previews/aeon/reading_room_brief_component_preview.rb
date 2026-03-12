# frozen_string_literal: true

module Aeon
  class ReadingRoomBriefComponentPreview < ViewComponent::Preview
    layout 'lookbook'

    # @!group Variations
    def spec
      @reading_room = Aeon::ReadingRoom.find_by(site: 'SPECUA')

      render Aeon::ReadingRoomBriefComponent.new(reading_room: @reading_room)
    end

    def rumsey
      @reading_room = Aeon::ReadingRoom.find_by(site: 'RUMSEY')

      render Aeon::ReadingRoomBriefComponent.new(reading_room: @reading_room)
    end

    def eal
      @reading_room = Aeon::ReadingRoom.find_by(site: 'EASTASIA')

      render Aeon::ReadingRoomBriefComponent.new(reading_room: @reading_room)
    end

    def ars
      @reading_room = Aeon::ReadingRoom.find_by(site: 'ARS')

      render Aeon::ReadingRoomBriefComponent.new(reading_room: @reading_room)
    end
    # @!endgroup
  end
end

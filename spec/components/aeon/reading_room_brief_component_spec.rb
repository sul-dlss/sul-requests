# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::ReadingRoomBriefComponent, type: :component do
  let(:reading_rooms) { JSON.load_file('spec/fixtures/reading_rooms.json') }

  before do
    render_inline(described_class.new(reading_room:))
  end

  context 'when Rumsey Reading Room' do
    let(:reading_room) { Aeon::ReadingRoom.from_dynamic(reading_rooms[0]) }

    it 'renders correctly' do
      expect(page).to have_content 'Rumsey Reading Room'
      expect(page).to have_content 'Located on the fourth floor of Green Library West.'
      expect(page).to have_content 'Hours: Monday - Friday, 1:00 - 4:30 pm'
    end
  end

  context 'when Archive of Recorded Sound' do
    let(:reading_room) { Aeon::ReadingRoom.from_dynamic(reading_rooms[1]) }
    let(:hours) { 'Hours: Monday - Wednesday, 9:00 - 3:00 pm, Thursday, 9:00 - 11:00 am and 12:00 - 3:00 pm, Friday, 9:00 - 3:00 pm' }

    it 'renders correctly' do
      expect(page).to have_content 'Archive of Recorded Sound'
      expect(page).to have_content 'Located in the basement of the Music Library.'
      expect(page).to have_content hours
    end
  end

  context 'when East Asia Library Reading Room' do
    let(:reading_room) { Aeon::ReadingRoom.from_dynamic(reading_rooms[2]) }

    it 'renders correctly' do
      expect(page).to have_content 'East Asia Library Special Collections'
      expect(page).to have_content 'Located on the second floor of Lathrop building.'
      expect(page).to have_content 'Hours: Monday - Friday, 9:00 - 5:00 pm'
    end
  end

  context 'when Field Reading Room' do
    let(:reading_room) { Aeon::ReadingRoom.from_dynamic(reading_rooms[3]) }

    it 'renders correctly' do
      expect(page).to have_content 'Field Reading Room'
      expect(page).to have_content 'Located on the second floor of Green Library West.'
      expect(page).to have_content 'Hours: Monday - Friday, 9:00 - 4:45 pm'
    end
  end
end

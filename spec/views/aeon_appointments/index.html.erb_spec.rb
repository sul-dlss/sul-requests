# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'aeon_appointments/index.html.erb' do
  before do
    allow(controller).to receive_messages(current_user: build(:sso_user))
    assign(:appointments, appointments)
    render
  end

  let(:appointments) { [] }

  it 'has a title' do
    expect(rendered).to have_css('h1', text: 'Reading room appointments')
  end

  context 'with multiple appointments on the same day' do
    let(:appointments) do
      [
        build(:aeon_appointment, start_time: Time.zone.parse('2024-03-11T21:00:00Z')),
        build(:aeon_appointment, start_time: Time.zone.parse('2024-03-11T22:00:00Z')),
        build(:aeon_appointment, start_time: Time.zone.parse('2024-03-12T21:00:00Z'), reading_room: build(:aeon_reading_room)),
        build(:aeon_appointment, start_time: Time.zone.parse('2024-03-12T21:00:00Z'),
                                 reading_room: build(:aeon_reading_room, id: 6, name: 'Other Reading Room', sites: ['Other']))
      ]
    end

    it 'displays appointments in a list' do
      expect(rendered).to have_css('h2', text: /Mar 11, 2024.*Field Reading Room/m)
      expect(rendered).to have_css('h2', text: /Mar 11, 2024.*Field Reading Room/m)
      expect(rendered).to have_css('h2', text: /Mar 12, 2024.*Field Reading Room/m)
      expect(rendered).to have_css('h2', text: /Mar 12, 2024.*2:00 pm - 1:15 pm.*Other Reading Room/m)
    end
  end
end

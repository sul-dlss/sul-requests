# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Message do
  subject(:message) { described_class.new }

  describe '#active?' do
    it "is not active if it hasn't been scheduled" do
      expect(message).not_to be_active
    end

    it 'is active if it is scheduled during the given time' do
      message.start_at = 1.minute.ago
      message.end_at = 1.minute.from_now
      expect(message).to be_active
    end

    it 'is not active if it is before the scheduled time' do
      message.start_at = 1.minute.from_now
      message.end_at = 5.minutes.from_now
      expect(message).not_to be_active
    end

    it 'is not active if it is after the scheduled time' do
      message.start_at = 5.minutes.ago
      message.end_at = 1.minute.ago
      expect(message).not_to be_active
    end
  end

  describe '#scheduled?' do
    it 'is scheduled if the start and end times are set' do
      message.start_at = 1.minute.ago
      message.end_at = 1.minute.from_now
      expect(message).to be_scheduled
    end

    it 'is not scheduled if the start time is not set' do
      message.end_at = 1.minute.from_now
      expect(message).not_to be_scheduled
    end

    it 'is not scheduled if the end time is not set' do
      message.start_at = 1.minute.ago
      expect(message).not_to be_scheduled
    end
  end

  describe '#title' do
    before do
      message.request_type = 'page'
      message.library = 'ARS'
    end

    it 'constructs a title from the request type and library' do
      expect(message.title).to eq 'Page from Archive of Recorded Sound'
    end
  end
end

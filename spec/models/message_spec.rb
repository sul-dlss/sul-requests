# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Message, type: :model do
  describe '#active?' do
    it "is not active if it hasn't been scheduled" do
      expect(subject).not_to be_active
    end

    it 'is active if it is scheduled during the given time' do
      subject.start_at = 1.minute.ago
      subject.end_at = 1.minute.from_now
      expect(subject).to be_active
    end

    it 'is not active if it is before the scheduled time' do
      subject.start_at = 1.minute.from_now
      subject.end_at = 5.minutes.from_now
      expect(subject).not_to be_active
    end

    it 'is not active if it is after the scheduled time' do
      subject.start_at = 5.minutes.ago
      subject.end_at = 1.minute.ago
      expect(subject).not_to be_active
    end
  end

  describe '#scheduled?' do
    it 'is scheduled if the start and end times are set' do
      subject.start_at = 1.minute.ago
      subject.end_at = 1.minute.from_now
      expect(subject).to be_scheduled
    end

    it 'is not scheduled if the start time is not set' do
      subject.end_at = 1.minute.from_now
      expect(subject).not_to be_scheduled
    end

    it 'is not scheduled if the end time is not set' do
      subject.start_at = 1.minute.ago
      expect(subject).not_to be_scheduled
    end
  end

  describe '#title' do
    before do
      subject.request_type = 'page'
      subject.library = 'ARS'
    end

    it 'constructs a title from the request type and library' do
      expect(subject.title).to eq 'Page from Archive of Recorded Sound'
    end
  end
end

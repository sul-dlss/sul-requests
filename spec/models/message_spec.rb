require 'rails_helper'

describe Message, type: :model do
  describe '#active?' do
    it "is not active if it hasn't been scheduled" do
      expect(subject).not_to be_active
    end

    it 'is active if it is scheduled during the given time' do
      subject.start_at = Time.zone.now - 1.minute
      subject.end_at = Time.zone.now + 1.minute
      expect(subject).to be_active
    end

    it 'is not active if it is before the scheduled time' do
      subject.start_at = Time.zone.now + 1.minute
      subject.end_at = Time.zone.now + 5.minutes
      expect(subject).not_to be_active
    end
    it 'is not active if it is after the scheduled time' do
      subject.start_at = Time.zone.now - 5.minutes
      subject.end_at = Time.zone.now - 1.minute
      expect(subject).not_to be_active
    end
  end

  describe '#scheduled?' do
    it 'is scheduled if the start and end times are set' do
      subject.start_at = Time.zone.now - 1.minute
      subject.end_at = Time.zone.now + 1.minute
      expect(subject).to be_scheduled
    end

    it 'is not scheduled if the start time is not set' do
      subject.end_at = Time.zone.now + 1.minute
      expect(subject).not_to be_scheduled
    end
    it 'is not scheduled if the end time is not set' do
      subject.start_at = Time.zone.now - 1.minute
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

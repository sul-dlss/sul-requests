# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::RequestFinders do
  before do
    allow(Aeon::Queue).to receive(:find_by) do |id: nil, **_kwargs|
      Aeon::Queue.from_dynamic(StubAeonClient::Queue.find_by(id: id).as_json) if id
    end
  end

  let(:now) { Time.zone.now }

  describe '#newest_first' do
    let(:older) do
      build(:aeon_request, item_title: 'Older',
                           creation_date: now - 2.days,
                           transaction_date: now - 1.day)
    end
    let(:newer) do
      build(:aeon_request, item_title: 'Newer',
                           creation_date: now - 1.day,
                           transaction_date: now - 2.days)
    end

    it 'sorts by creation_date descending by default' do
      finders = described_class.new([older, newer])

      expect(finders.newest_first.map(&:title)).to eq %w[Newer Older]
    end

    it 'sorts by the given timestamp accessor when a block is provided' do
      finders = described_class.new([older, newer])

      expect(finders.newest_first(&:transaction_date).map(&:title)).to eq %w[Older Newer]
    end

    it 'breaks ties on creation_date using title, then sort_key' do
      tied_time = now - 1.day
      first_alpha = build(:aeon_request,
                          transaction_number: 1, item_title: 'Apples',
                          call_number: 'AAA', creation_date: tied_time)
      second_alpha = build(:aeon_request,
                           transaction_number: 2, item_title: 'Bananas',
                           call_number: 'AAA', creation_date: tied_time)
      same_title_higher_sort_key = build(:aeon_request,
                                         transaction_number: 3, item_title: 'Apples',
                                         call_number: 'ZZZ', creation_date: tied_time)

      finders = described_class.new([second_alpha, same_title_higher_sort_key, first_alpha])

      expect(finders.newest_first.map(&:transaction_number)).to eq [1, 3, 2]
    end

    it 'ignores sub-minute differences in the timestamp' do
      a = build(:aeon_request, item_title: 'Apples',
                               creation_date: now.change(sec: 5))
      b = build(:aeon_request, item_title: 'Bananas',
                               creation_date: now.change(sec: 55))

      finders = described_class.new([b, a])

      expect(finders.newest_first.map(&:title)).to eq %w[Apples Bananas]
    end

    it 'returns a RequestFinders instance' do
      finders = described_class.new([older, newer])

      expect(finders.newest_first).to be_a(described_class)
    end
  end

  describe '#recently_delivered' do
    let(:recently_delivered) do
      build(:aeon_request, :digitized,
            item_title: 'Recent',
            transaction_status: 17, photoduplication_status: 23,
            photoduplication_date: 1.day.ago)
    end
    let(:long_ago_delivered) do
      build(:aeon_request, :digitized,
            item_title: 'Stale',
            transaction_status: 17, photoduplication_status: 23,
            photoduplication_date: 10.days.ago)
    end
    let(:not_delivered) do
      build(:aeon_request, item_title: 'Pending',
                           shipping_option: nil,
                           transaction_status: 8, photoduplication_status: nil)
    end

    it 'returns only requests delivered within the default 3-day window' do
      finders = described_class.new([recently_delivered, long_ago_delivered, not_delivered])

      expect(finders.recently_delivered.map(&:title)).to eq %w[Recent]
    end

    it 'respects a custom window' do
      finders = described_class.new([recently_delivered, long_ago_delivered, not_delivered])

      expect(finders.recently_delivered(within: 30.days).map(&:title))
        .to contain_exactly('Recent', 'Stale')
    end

    it 'returns a RequestFinders instance' do
      finders = described_class.new([recently_delivered])

      expect(finders.recently_delivered).to be_a(described_class)
    end
  end
end

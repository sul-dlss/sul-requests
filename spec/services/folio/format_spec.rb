# frozen_string_literal: true

require 'rails_helper'

# The per-rule format classifications (Book, Journal/Periodical, Video/Film|DVD, etc.)
# are tested in searchworks_traject_indexer. Here we run a simple smoke test.
RSpec.describe Folio::Format do
  subject(:formats) { described_class.compute(marc_record:) }

  context 'with no MARC record' do
    let(:marc_record) { nil }

    it 'returns an empty array' do
      expect(formats).to eq([])
    end
  end

  context 'with a MARC record that matches a format rule' do
    let(:marc_record) do
      MARC::Record.new.tap do |r|
        r.leader = '01044cam a2200277 a 4500'
        r.append(MARC::ControlField.new('008', '950925s1996    nyu           000 0 eng d'))
      end
    end

    it 'runs the copied searchworks_traject_indexer format rules and returns their (deduped) accumulated output' do
      expect(formats).to include('Book')
      expect(formats).to eq(formats.uniq)
    end
  end
end

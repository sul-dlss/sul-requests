# frozen_string_literal: true

RSpec.shared_examples 'folio_record' do |args = []|
  let(:model) { described_class.new(*args.dup.unshift(record)) }

  let(:record) do
    { 'id' => '6f951192-b633-40a0-8112-73a191b55a8a',
      'item' =>
       { 'title' =>
         'The making of American liberal theology / Gary Dorrien.',
         'author' => 'Dorrien, Gary J',
         'instanceId' => '948b80ac-a7fa-5577-87b4-7494ee4c7482',
         'itemId' => '6d9a4f99-d144-51cf-92d7-3edbfc588abe',
         'instance' =>
         { 'hrid' =>
           'a1234565' },
         'item' =>
         { 'barcode' => '36105110374977',
           'effectiveShelvingOrder' => 'ND237 R725 A4 2017 F',
           'effectiveCallNumberComponents' => { 'callNumber' => 'ND237 .R725 A4 2017 F' } } } }
  end

  describe '#catkey' do
    it { expect(model.catkey).to eq 'a1234565' }
  end

  describe '#title' do
    it { expect(model.title).to eq 'The making of American liberal theology / Gary Dorrien.' }
  end

  describe '#author' do
    it { expect(model.author).to eq 'Dorrien, Gary J' }
  end

  describe '#call_number' do
    it { expect(model.call_number).to eq 'ND237 .R725 A4 2017 F' }
  end

  describe '#shelf_key' do
    it { expect(model.shelf_key).to eq 'ND237 R725 A4 2017 F' }
  end

  describe '#barcode' do
    it { expect(model.barcode).to eq '36105110374977' }
  end

  describe '#item_id' do
    it { expect(model.item_id).to eq '6d9a4f99-d144-51cf-92d7-3edbfc588abe' }
  end
end

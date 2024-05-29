# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper do
  describe '#dialog_column_class' do
    it 'returns a string representing the main dialog class' do
      expect(dialog_column_class).to eq 'col-lg-6 offset-lg-3'
    end
  end

  describe '#label_column_offset_class' do
    it 'is defined to help when offseting non-labeled form elements (e.g. buttons)' do
      expect(label_column_offset_class).to eq 'offset-sm-4'
    end
  end

  describe '#render_markdown' do
    it 'renders markup to markdown' do
      expect(helper.render_markdown('**abc**')).to include content_tag(:strong, 'abc')
    end
  end

  describe '#sort_holdings_records' do
    let(:all_items) do
      [
        build(:item, base_callnumber: 'ABC 123', full_enumeration: rec_one_enumeration, enumeration: rec_one_enumeration,
                     barcode: '123123124'),
        build(:item, base_callnumber: 'ABC 123', full_enumeration: rec_two_enumeration, enumeration: rec_two_enumeration,
                     barcode: '9928812')
      ]
    end
    let(:sorted_holdings) { sort_holdings(all_items) }

    context 'when date with volume' do
      let(:rec_one_enumeration) { 'V12 2020' }
      let(:rec_two_enumeration) { 'V12 2021' }

      it 'expects to sort desc by date' do
        expect(sorted_holdings.first.barcode).to equal('9928812')
      end
    end

    context 'when volume with letter' do
      let(:rec_one_enumeration) { 'V12' }
      let(:rec_two_enumeration) { 'V12A' }

      it 'expects sort asc by volume and letter' do
        expect(sorted_holdings.first.barcode).to equal('123123124')
      end
    end

    context 'when one item has no enumeration' do
      let(:rec_one_enumeration) { '' }
      let(:rec_two_enumeration) { '12' }

      it 'expects items with no enumeration first' do
        expect(sorted_holdings.first.barcode).to equal('123123124')
      end
    end

    context 'when there are months in barcode' do
      let(:rec_one_enumeration) { 'JANUARY-MARCH 2021' }
      let(:rec_two_enumeration) { 'Dec 2020:Apr 2021' }

      it 'expects newest month/year combo to be first' do
        expect(sorted_holdings.first.barcode).to equal('9928812')
      end
    end

    context 'when there are months, years, and volumes in barcode' do
      let(:rec_one_enumeration) { 'JANUARY-MARCH 2021 1' }
      let(:rec_two_enumeration) { 'Feb-MARCH 2021 12' }

      it 'expects to sort by volume due to same end month' do
        expect(sorted_holdings.first.barcode).to equal('123123124')
      end
    end
  end
end

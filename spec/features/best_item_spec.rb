# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Best item selection' do
  it 'selects the only item' do
    expect(PatronRequest.new(instance_hrid: 'a24434').best_item.barcode).to eq '36105033468641'
  end

  it 'selects the requestable item' do
  end

  it 'selects the fastest delivery to GREEN' do
    # 964832 => 36105037028326 (GREEN) or 36105003949125 (SAL3)
  end

  it 'selects the fastest delivery to HOPKINS' do
    # in00000061551 => 36105243759409 (GREEN) or 36105243618316 (SAL3)
  end

  context 'unknown best items' do
    it 'does not handle mixed-material' do
      # a6522956
    end

    it 'does not handle serials' do
      # in00000113148
    end
  end
end

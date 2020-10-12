# frozen_string_literal: true

require 'rails_helper'

describe 'CDL' do
  describe 'availablity api' do
    it 'provides a JSON response' do
      visit cdl_availability_path(barcode: 'abc123')
      expect(JSON.parse(page.body)).to include(
        'available' => false,
        'dueDate' => nil,
        'items' => 0,
        'loanPeriod' => 7200,
        'waitlist' => 0
      )
    end
  end
end

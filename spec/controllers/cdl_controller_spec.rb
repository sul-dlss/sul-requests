# frozen_string_literal: true

require 'rails_helper'

describe CdlController do
  describe '#availability' do
    it 'is accessible by anyone' do
      get :availability, params: { barcode: 'abc123' }
      expect(response).to be_successful
    end
  end
end

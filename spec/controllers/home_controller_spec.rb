# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HomeController do
  describe '#show' do
    it 'is successful' do
      get :show
      expect(response).to be_successful
    end
  end
end

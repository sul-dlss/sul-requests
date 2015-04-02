require 'rails_helper'

describe HomeController do
  describe '#show' do
    it 'should be successful' do
      get :show
      expect(response).to be_successful
    end
  end
end

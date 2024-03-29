# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Honey Pot Fields' do
  let(:user) { create(:sso_user) }

  before do
    stub_bib_data_json(build(:single_holding))
    stub_current_user(user)
  end

  context 'Email field' do
    it 'raises an error if the field has been filled out' do
      visit new_page_path(item_id: '1234', origin: 'SAL3', origin_location: 'SAL3-STACKS')

      hidden_field = find_by_id('email', visible: :hidden)
      hidden_field.set('some-email')

      expect do
        first(:button, 'Send request').click
      end.to raise_error(RequestsController::HoneyPotFieldError)
    end
  end
end

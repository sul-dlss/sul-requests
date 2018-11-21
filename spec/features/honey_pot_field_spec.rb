# frozen_string_literal: true

require 'rails_helper'

describe 'Honey Pot Fields' do
  let(:user) { create(:webauth_user) }
  before { stub_current_user(user) }
  context 'Email field' do
    it 'raises an error if the field has been filled out' do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')

      hidden_field = find('#email', visible: false)
      hidden_field.set('some-email')

      expect(
        -> { first(:button, 'Send request').click }
      ).to raise_error(RequestsController::HoneyPotFieldError)
    end
  end
end

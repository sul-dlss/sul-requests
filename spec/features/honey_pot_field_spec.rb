# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Honey Pot Fields' do
  let(:user) { create(:sso_user) }

  before do
    allow_any_instance_of(FolioClient).to receive(:find_instance).and_return({ title: 'Test title' })
    allow_any_instance_of(FolioClient).to receive(:resolve_to_instance_id).and_return('f1c52ab3-721e-5234-9a00-1023e034e2e8')
    stub_folio_holdings(:empty)
    stub_current_user(user)
  end

  context 'Email field' do
    it 'raises an error if the field has been filled out' do
      visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')

      hidden_field = find_by_id('email', visible: :hidden)
      hidden_field.set('some-email')

      expect do
        first(:button, 'Send request').click
      end.to raise_error(RequestsController::HoneyPotFieldError)
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Honey Pot Fields' do
  let(:user) { create(:sso_user) }
  let(:holdings_relationship) { double(:relationship, where: [], all: [], single_checked_out_item?: false) }

  before do
    allow(Settings.ils.bib_model.constantize).to receive(:new).and_return(double(:bib_data, title: 'Test title'))
    allow(HoldingsRelationshipBuilder).to receive(:build).and_return(holdings_relationship)
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

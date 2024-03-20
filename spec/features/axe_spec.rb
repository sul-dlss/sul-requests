# frozen_string_literal: true

require 'rails_helper'
require 'axe-rspec'

RSpec.describe 'Accessibility testing', :js do
  # TODO: once user login is avaliable add user mocks
  # TODO: add patron_request_path after built out more
  it 'validates the home page' do
    visit new_patron_request_path
    expect(page).to be_accessible
  end

  def be_accessible
    be_axe_clean
  end
end

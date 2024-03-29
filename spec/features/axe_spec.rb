# frozen_string_literal: true

require 'rails_helper'
require 'axe-rspec'

RSpec.describe 'Accessibility testing', :js do
  before do
    allow(Folio::Instance).to receive(:fetch).with('a12345').and_return(build(:sal3_holding))
  end

  # TODO: once user login is avaliable add user mocks
  # TODO: add patron_request_path after built out more
  it 'validates the home page' do
    visit new_patron_request_path(instance_hrid: 'a12345', origin_location_code: 'SAL3')
    expect(page).to be_accessible
  end

  context 'with a user' do
    let(:user) { instance_double(CurrentUser, user_object: build(:sso_user)) }

    before do
      login_as(user)
    end

    it 'validates the request page' do
      visit new_patron_request_path(instance_hrid: 'a12345', origin_location_code: 'SAL3', step: 'select')
      expect(page).to be_accessible
    end
  end

  it 'validates the feedback form page' do
    visit feedback_form_path
    expect(page).to be_accessible
  end

  def be_accessible
    be_axe_clean
  end
end

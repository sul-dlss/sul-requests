# frozen_string_literal: true

require 'rails_helper'
require 'axe-rspec'

RSpec.describe 'Accessibility testing', :js do
  before do
    allow(Folio::Instance).to receive(:fetch).with('a12345').and_return(build(:sal3_holding))
  end

  # TODO: once user login is avaliable add user mocks
  # TODO: add patron_request_path after built out more
  describe 'without user login' do
    it 'validates the home page' do
      visit new_patron_request_path(instance_hrid: 'a12345', origin_location_code: 'SAL3-STACKS')
      expect(page).to be_accessible
    end

    it 'validates the feedback form page' do
      visit feedback_form_path
      expect(page).to be_accessible
    end
  end

  context 'with a user' do
    let(:user) { instance_double(CurrentUser, user_object: build(:sso_user)) }

    before do
      login_as(user)
    end

    it 'validates the request page' do
      visit new_patron_request_path(instance_hrid: 'a12345', origin_location_code: 'SAL3-STACKS', step: 'select')
      expect(page).to be_accessible
    end
  end

  it 'validates the feedback form page' do
    visit feedback_form_path
    expect(page).to be_accessible
  end

  describe 'with a blocked user login' do
    let(:user) { build(:sso_user) }
    let(:patron) do
      instance_double(Folio::Patron, id: user.patron_key, display_name: 'A User', exists?: true, email: nil,
                                     patron_group: { desc: 'faculty' },
                                     allowed_request_types: ['Hold', 'Recall'],
                                     ilb_eligible?: true, blocks: ['there is a block'])
    end

    before do
      login_as(instance_double(CurrentUser, user_object: user))
      allow(Settings.ils.patron_model.constantize).to receive(:find_by).with(patron_key: user.patron_key).and_return(patron)
    end

    it 'validates the home page' do
      visit new_patron_request_path(instance_hrid: 'a12345', origin_location_code: 'SAL3-STACKS', step: 'select')
      expect(page).to be_accessible
    end
  end

  def be_accessible
    be_axe_clean
  end
end

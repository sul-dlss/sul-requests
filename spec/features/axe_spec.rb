# frozen_string_literal: true

require 'rails_helper'
require 'axe-rspec'

RSpec.describe 'Accessibility testing', :js do
  let(:user_object) { build(:sso_user) }

  before do
    allow(Folio::Instance).to receive(:fetch).with('a12345').and_return(build(:sal3_holding))
  end

  # TODO: once user login is available add user mocks
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
    let(:user) { instance_double(CurrentUser, user_object:, shibboleth?: true, name_email_user?: false) }
    let(:patron) { build(:patron) }

    before do
      login_as(user)
      allow(Settings.ils.patron_model.constantize).to receive(:find_by).with(patron_key: user_object.patron_key).and_return(patron)
    end

    it 'validates the request page' do
      visit new_patron_request_path(instance_hrid: 'a12345', origin_location_code: 'SAL3-STACKS', step: 'select')
      expect(page).to be_accessible
    end

    context 'when the user is blocked' do
      let(:patron) { build(:blocked_patron) }

      it 'validates the request page' do
        visit new_patron_request_path(instance_hrid: 'a12345', origin_location_code: 'SAL3-STACKS', step: 'select')
        expect(page).to be_accessible
      end
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

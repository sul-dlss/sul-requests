# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController do
  describe '#current_user' do
    before do
      warden.set_user(CurrentUser.new({ 'username' => 'test', 'shibboleth' => true }))
    end

    it 'returns an application user object when there is a logged-in user' do
      expect(controller.current_user).to have_attributes(sso_user?: true, sunetid: 'test')
    end
  end

  describe '#search_patron_request' do
    before do
      controller.params = ActionController::Parameters.new(request_type: ['Page'])
      mock_all = [build(:page_patron_request), build(:page_patron_request), build(:mediated_patron_request)]

      allow(PatronRequest).to receive(:all).and_return(mock_all)
    end

    it 'returns filtered results' do
      expect(controller.send(:search_patron_request).length).to be 2
    end
  end
end

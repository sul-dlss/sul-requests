# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestsController do
  before do
    stub_current_user(user)
    allow(Settings.ils.bib_model.constantize).to receive(:fetch)
  end

  describe '#status' do
    context 'by sso users' do
      let(:user) { create(:sso_user) }

      it 'is successful if they have the are the creator of the record' do
        page = create(:page, user:)
        get :status, params: { id: page[:id] }
        expect(response).to be_successful
      end

      it 'is forbidden when the user is already authenticated but does not have access to the request' do
        page = create(:page)
        get :status, params: { id: page[:id] }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'by non-webuth users' do
      let(:user) { create(:non_sso_user) }

      it 'redirects the user to the sso login with the current url' do
        page = create(:page, user: create(:non_sso_user, email: 'jjstanford@stanford.edu'))
        get :status, params: { id: page[:id] }
        expect(response).to redirect_to(
          login_by_sunetid_path(
            referrer: status_request_url(page[:id])
          )
        )
      end
    end
  end
end

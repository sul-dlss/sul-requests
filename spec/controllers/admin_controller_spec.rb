# frozen_string_literal: true

require 'rails_helper'

describe AdminController do
  before do
    stub_current_user(user)
  end

  describe 'index' do
    describe 'for super admin' do
      let(:user) { create(:superadmin_user) }

      it 'is accessible' do
        get :index
        expect(response).to be_successful
      end
    end

    describe 'for site admin' do
      let(:user) { create(:site_admin_user) }

      it 'is accessible' do
        get :index
        expect(response).to be_successful
      end
    end

    describe 'for sso user' do
      let(:user) { create(:sso_user) }

      it 'is not accessible' do
        get :index
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'for anon user' do
      let(:user) { create(:anon_user) }

      it 'redirects to the login page' do
        expect(get(:index)).to redirect_to(login_path(referrer: admin_index_url))
      end
    end
  end

  describe 'show' do
    describe 'for super admin' do
      let(:user) { create(:superadmin_user) }

      it 'is accessible' do
        get :show, params: { id: 'SAL3' }
        expect(response).to be_successful
      end
    end

    describe 'for site admin' do
      let(:user) { create(:site_admin_user) }

      it 'is accessible' do
        get :show, params: { id: 'SAL3' }
        expect(response).to be_successful
      end
    end

    describe 'for origin admin' do
      let(:user) { create(:art_origin_admin_user) }

      it 'is accessible when the user is an admin for the location' do
        get :show, params: { id: 'ART' }
        expect(response).to be_successful
      end

      it 'is not be accessible when the user is not an admin for the location' do
        get :show, params: { id: 'SPEC-COLL' }
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'for normal webuath user' do
      let(:user) { create(:sso_user) }

      it 'is not be accessible' do
        get :show, params: { id: 'SPEC-COLL' }
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'for anonymouse users' do
      let(:user) { create(:anon_user) }

      it 'redirects to login' do
        expect(get(:show, params: { id: 'SPEC-COLL' })).to redirect_to(
          login_path(referrer: admin_url('SPEC-COLL'))
        )
      end
    end
  end

  describe 'holdings' do
    describe 'for super admins' do
      let(:user) { create(:superadmin_user) }
      let(:mediated_page) do
        create(:mediated_page_with_holdings, user: create(:non_sso_user), barcodes: %w(12345678 23456789))
      end

      it 'returns the holdings table markup' do
        get :holdings, params: { id: mediated_page.id }
        expect(response).to be_successful
        expect(assigns(:request)).to be_a(MediatedPage)
      end

      it 'initiates a mediated page object with the live_lookup option set to false' do
        get :holdings, params: { id: mediated_page.id }
        expect(assigns(:request).live_lookup).to be false
      end
    end
  end

  describe 'approve item' do
    before { stub_searchworks_api_json(build(:searchable_holdings)) }

    let(:mediated_page) do
      create(:mediated_page_with_holdings, user: create(:sso_user), barcodes: %w(12345678 23456789))
    end

    describe 'for those that can manage requests' do
      let(:user) { create(:superadmin_user) }

      it 'can approve individual items' do
        expect(MediatedPage.find(mediated_page.id).request_status_data).to be_blank
        stub_symphony_response(build(:symphony_page_with_single_item))
        get :approve_item, params: { id: mediated_page.id, item: '3610512345' }
        expect(response).to be_successful

        expect(
          MediatedPage.find(mediated_page.id).request_status_data['3610512345']['approved']
        ).to be true
      end

      it 'returns a 500 when the item cannot be approved' do
        get :approve_item, params: { id: mediated_page.id, item: '3610512345' }
        expect(response).to have_http_status :internal_server_error
        expect(response).not_to be_successful
      end

      it 'initiates a mediated page object with the live_lookup option set to false' do
        get :approve_item, params: { id: mediated_page.id, item: '3610512345' }
        expect(assigns(:request).live_lookup).to be false
      end
    end

    describe 'for anonymous users' do
      let(:user) { create(:anon_user) }

      it 'is not possible' do
        get :approve_item, params: { id: mediated_page.id, item: 'ABC 123' }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end

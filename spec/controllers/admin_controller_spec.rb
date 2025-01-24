# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminController do
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
        expect { get :index }.to raise_error(CanCan::AccessDenied)
      end
    end

    describe 'for anon user' do
      let(:user) { create(:anon_user) }

      it 'redirects to the login page' do
        expect(get(:index)).to redirect_to(login_by_sunetid_path(referrer: admin_index_url))
      end
    end
  end

  describe 'show' do
    before do
      create(:mediated_patron_request_with_holdings, barcodes: %w(123456))
    end

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
        expect { get :show, params: { id: 'SPEC-COLL' } }.to raise_error(CanCan::AccessDenied)
      end
    end

    describe 'for normal webuath user' do
      let(:user) { create(:sso_user) }

      it 'is not be accessible' do
        expect { get :show, params: { id: 'SPEC-COLL' } }.to raise_error(CanCan::AccessDenied)
      end
    end

    describe 'for anonymouse users' do
      let(:user) { create(:anon_user) }

      it 'redirects to login' do
        expect(get(:show, params: { id: 'SPEC-COLL' })).to redirect_to(
          login_by_sunetid_path(referrer: admin_url('SPEC-COLL'))
        )
      end
    end
  end

  describe 'holdings' do
    describe 'for super admins' do
      let(:user) { create(:superadmin_user) }
      let(:mediated_page) do
        create(:mediated_patron_request_with_holdings, barcodes: %w(12345678 23456789))
      end

      before do
        allow_any_instance_of(PatronRequest).to receive(:bib_data).and_return(build(:searchable_holdings))
      end

      it 'returns the holdings table markup' do
        get :holdings, params: { id: mediated_page.id }
        expect(response).to be_successful
        expect(assigns(:request)).to be_a(PatronRequest)
      end
    end
  end

  describe 'approve item' do
    let(:mediated_page) do
      create(:mediated_patron_request_with_holdings, barcodes: %w(12345678 23456789))
    end

    before do
      allow_any_instance_of(PatronRequest).to receive(:bib_data).and_return(build(:searchable_holdings))
    end

    describe 'for those that can manage requests' do
      let(:user) { create(:superadmin_user) }

      it 'can approve individual items' do
        expect(PatronRequest.find(mediated_page.id).item_mediation_data).to be_blank
        get :approve_item, params: { id: mediated_page.id, item: '3610512345' }
        expect(response).to be_successful

        expect(
          PatronRequest.find(mediated_page.id).item_mediation_data['3610512345']['approved']
        ).to be true
      end
    end

    describe 'for anonymous users' do
      let(:user) { create(:anon_user) }

      it 'is not possible' do
        expect { get :approve_item, params: { id: mediated_page.id, item: 'ABC 123' } }.to raise_error(CanCan::AccessDenied)
      end
    end
  end
end

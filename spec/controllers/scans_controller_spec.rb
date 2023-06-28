# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ScansController do
  before do
    stub_searchworks_api_json(build(:sal3_holdings))
    allow(SubmitScanRequestJob).to receive(:perform_later)
    allow(controller).to receive_messages(current_user: user)
  end

  let(:scan) { create(:scan, :with_holdings, origin: 'SAL', origin_location: 'STACKS', barcodes: ['12345678']) }
  let(:scannable_params) do
    { item_id: '12345', origin: 'SAL3', origin_location: 'STACKS' }
  end

  describe 'new' do
    let(:user) { create(:anon_user) }

    it 'is accessible by anonymous users' do
      get :new, params: scannable_params
      expect(response).to be_successful
    end

    it 'sets defaults' do
      get :new, params: scannable_params
      expect(assigns[:request].origin).to eq 'SAL3'
      expect(assigns[:request].origin_location).to eq 'STACKS'
      expect(assigns[:request].item_id).to eq '12345'
    end

    it 'raises an error when an unscannable item is requested' do
      expect do
        get :new, params: { item_id: '12345', origin: 'SAL1/2', origin_location: 'STACKS' }
      end.to raise_error(ScansController::UnscannableItemError)
    end
  end

  describe 'create' do
    describe 'by anonymous users' do
      let(:user) { create(:anon_user) }

      it 'redirects to the login page passing a refferrer param to continue creating your request' do
        post :create, params: { request: { item_id: '12345', origin: 'GREEN', origin_location: 'STACKS' } }
        expect(response).to redirect_to(
          login_path(
            referrer: interstitial_path(
              redirect_to: create_scans_url(
                request: { item_id: '12345', origin: 'GREEN', origin_location: 'STACKS' }
              )
            )
          )
        )
      end

      it 'is not allowed by users that only supply name and email' do
        expect do
          put :create, params: {
            request: {
              item_id: '12345',
              origin: 'SAL3',
              origin_location: 'STACKS',
              user_attributes: { name: 'Jane Stanford', email: 'jstanford@stanford.edu' }
            }
          }
        end.to raise_error(CanCan::AccessDenied)
      end

      it 'is not allowed by users that only supply a library id' do
        expect do
          put :create, params: {
            request: {
              item_id: '12345',
              origin: 'SAL3',
              origin_location: 'STACKS',
              user_attributes: { library_id: '12345' }
            }
          }
        end.to raise_error(CanCan::AccessDenied)
      end

      describe 'via get' do
        it 'raises an error' do
          expect do
            get :create, params: { request: { item_id: '12345', origin: 'GREEN', origin_location: 'STACKS' } }
          end.to raise_error(CanCan::AccessDenied)
        end
      end
    end

    describe 'by non-sso users' do
      let(:user) { create(:non_sso_user) }

      it 'raises an error' do
        expect { put(:create, params: { request: { origin: 'SAL3' } }) }.to raise_error(CanCan::AccessDenied)
      end
    end

    describe 'by eligible users' do
      let(:user) { create(:scan_eligible_user) }

      before do
        post :create, params: {
          request: {
            item_id: '12345',
            origin: 'SAL3',
            origin_location: 'STACKS',
            barcodes: ['87654321'],
            section_title: 'Some really important chapter'
          }
        }
      end

      it 'is allowed' do
        expect(Scan.last.origin).to eq 'SAL3'
        expect(Scan.last.user).to eq user
        expect(Scan.last.barcodes).to eq(['87654321'])
      end

      it 'redirects to the scan success page after a successful illiad request' do
        expect(SubmitScanRequestJob).to have_received(:perform_later).with(Scan.last)
      end
    end

    describe 'by ineligible users' do
      render_views

      let(:user) { create(:sso_user) }

      it 'is bounced to a page workflow' do
        params = {
          request: { item_id: '12345', origin: 'SAL3', origin_location: 'STACKS', barcodes: { '12345678' => '1' } }
        }
        post(:create, params:)
        expect(flash[:error]).to include 'Scan-to-PDF not available'
        expect(response).to redirect_to new_page_url(params[:request])
      end
    end
  end

  describe 'update' do
    before do
      allow(Request).to receive(:find).and_return(scan) # So that holdings are stubbed from FactoryBot
    end

    describe 'by anonymous users' do
      let(:user) { create(:anon_user) }

      it 'raises an error' do
        expect { put(:update, params: { id: scan[:id] }) }.to raise_error(CanCan::AccessDenied)
      end
    end

    describe 'invalid requests' do
      let(:user) { create(:superadmin_user) }

      before do
        allow_any_instance_of(scan.class).to receive(:update).with({}).and_return(false)
      end

      it 'returns an error message to the user' do
        put :update, params: { id: scan[:id], request: { item_id: nil } }
        expect(flash[:error]).to eq 'There was a problem updating your request.'
        expect(response).to render_template 'edit'
      end
    end

    describe 'by sso users' do
      let(:user) { create(:sso_user) }

      it 'raises an error' do
        expect { put(:update, params: { id: scan[:id] }) }.to raise_error(CanCan::AccessDenied)
      end
    end

    describe 'by superadmins' do
      let(:user) { create(:superadmin_user) }

      it 'is allowed to modify page requests' do
        put :update, params: { id: scan[:id], request: { needed_date: Time.zone.today + 1.day } }
        expect(response).to redirect_to root_url
        expect(flash[:success]).to eq 'Request was successfully updated.'
        expect(Scan.find(scan.id).needed_date.to_s).to eq((Time.zone.today + 1.day).to_s)
      end
    end
  end

  describe '#current_request' do
    let(:user) { create(:anon_user) }

    it 'returns a Scan object' do
      get :new, params: scannable_params
      expect(controller.send(:current_request)).to be_a(Scan)
    end
  end
end

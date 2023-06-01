# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HoldRecallsController do
  let(:hold_recall) { create(:hold_recall) }
  let(:normal_params) do
    { item_id: '1234', barcode: '36105212925395', origin: 'GREEN', origin_location: 'STACKS', destination: 'GREEN' }
  end

  let(:folio_holding_response) do
    { 'instanceId' => 'f1c52ab3-721e-5234-9a00-1023e034e2e8',
      'source' => 'MARC',
      'modeOfIssuance' => 'single unit',
      'natureOfContent' => [],
      'holdings' => [],
      'items' =>
       [{ 'id' => '584baef9-ea2f-5ff5-9947-bbc348aee4a4',
          'notes' => [],
          'status' => 'Available',
          'barcode' => '3610512345678',
          'location' =>
          { 'effectiveLocation' => { 'code' => 'GRE-STACKS' },
            'permanentLocation' => { 'code' => 'GRE-STACKS' },
            'temporaryLocation' => {} },
          'callNumber' => { 'callNumber' => 'PR6123 .E475 W42 2009' },
          'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
          'materialType' => 'book',
          'permanentLoanType' => 'Can circulate',
          'suppressFromDiscovery' => false },
        { 'id' => '99466f50-2b8c-51d4-8890-373190b8f6c4',
          'notes' => [],
          'status' => 'Available',
          'barcode' => '12345679',
          'location' =>
          { 'effectiveLocation' => { 'code' => 'GRE-STACKS' },
            'permanentLocation' => { 'code' => 'GRE-STACKS' },
            'temporaryLocation' => {} },
          'callNumber' => { 'callNumber' => 'PR6123 .E475 W42 2009' },
          'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
          'materialType' => 'book',
          'permanentLoanType' => 'Can circulate',
          'suppressFromDiscovery' => false },
        { 'id' => 'deec4ae9-545c-5d60-85b0-b1048b9dad05',
          'notes' => [],
          'status' => 'Available',
          'barcode' => '36105028330483',
          'location' =>
          { 'effectiveLocation' => { 'code' => 'GRE-STACKS' },
            'permanentLocation' => { 'code' => 'GRE-STACKS' },
            'temporaryLocation' => {} },
          'callNumber' => { 'callNumber' => 'PR6123 .E475 W42 2009' },
          'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
          'materialType' => 'book',
          'permanentLoanType' => 'Can circulate',
          'suppressFromDiscovery' => false }] }
  end

  before do
    allow_any_instance_of(FolioClient).to receive(:find_instance).and_return({ indexTitle: 'Item Title' })
    allow_any_instance_of(FolioClient).to receive(:resolve_to_instance_id).and_return('f1c52ab3-721e-5234-9a00-1023e034e2e8')
    allow_any_instance_of(FolioClient).to receive(:items_and_holdings).and_return(folio_holding_response)
    allow(controller).to receive_messages(current_user: user)
  end

  describe 'new' do
    let(:user) { create(:anon_user) }

    it 'is accessible by anonymous users' do
      get :new, params: normal_params
      expect(response).to be_successful
    end

    it 'sets defaults' do
      get :new, params: normal_params
      expect(assigns[:request].origin).to eq 'GREEN'
      expect(assigns[:request].origin_location).to eq 'STACKS'
      expect(assigns[:request].item_id).to eq '1234'
      expect(assigns[:request].needed_date).to eq Time.zone.today + 1.year
    end

    it 'raises an error if the item is unmediateable' do
      expect do
        get :new, params: { item_id: '1234', origin: 'GREEN', origin_location: 'STACKS', destination: 'ART' }
      end.to raise_error(HoldRecallsController::NotHoldRecallableError)
    end
  end

  describe 'create' do
    pending 'by anonymous users' do
      let(:user) { create(:anon_user) }

      it 'redirects to the login page passing a referrer param to continue creating the hold recall request' do
        post :create, params: { request: normal_params }
        expect(response).to redirect_to(
          login_path(
            referrer: interstitial_path(
              redirect_to: create_hold_recalls_url(
                request: normal_params
              )
            )
          )
        )
      end

      it 'is not allowed if user name and email is filled out' do
        put :create, params: {
          request: normal_params.merge(
            user_attributes: {
              name: 'Jane Stanford',
              email: 'jstanford@stanford.edu'
            }
          )
        }
        expect(response).to have_http_status(:forbidden)
      end

      it 'is allowed if the library ID field is filled out' do
        put :create, params: {
          request: {
            item_id: '1234',
            origin: 'SPEC-COLL',
            origin_location: 'STACKS',
            destination: 'SPEC-COLL',
            user_attributes: { library_id: '12345' }
          }
        }

        expect(response.location).to match(/#{successful_hold_recall_url(HoldRecall.last)}\?token=/)
        expect(User.last.library_id).to eq '12345'
        expect(HoldRecall.last.user).to eq User.last
      end

      describe 'via get' do
        it 'raises an error' do
          get :create, params: { request: normal_params }
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    describe 'by sso users' do
      let(:user) { create(:sso_user) }

      it 'is allowed' do
        post :create, params: { request: normal_params }
        expect(response).to redirect_to successful_hold_recall_path(HoldRecall.last)
        expect(HoldRecall.last.origin).to eq 'GREEN'
        expect(HoldRecall.last.user).to eq user
      end

      it 'sets a default needed_date if one is not present' do
        post :create, params: { request: normal_params }
        expect(HoldRecall.last.needed_date).to eq Time.zone.today + 1.year
      end

      it 'accepts a set needed_date when provided' do
        post :create, params: { request: normal_params.merge(needed_date: Time.zone.today + 1.month) }
        expect(HoldRecall.last.needed_date).to eq Time.zone.today + 1.month
      end
      # NOTE: cannot trigger activejob from this spec to check RequestStatusMailer
    end

    describe 'invalid requests' do
      let(:user) { create(:sso_user) }

      it 'returns an error message to the user' do
        post :create, params: { request: { item_id: '1234' } }
        expect(flash[:error]).to eq 'There was a problem creating your request.'
        expect(response).to render_template 'new'
      end
    end
  end

  describe '#current_request' do
    let(:user) { create(:anon_user) }

    it 'returns a HoldRecall object' do
      get :new, params: normal_params
      expect(controller.send(:current_request)).to be_a(HoldRecall)
    end
  end
end

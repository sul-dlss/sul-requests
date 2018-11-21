# frozen_string_literal: true

require 'rails_helper'

describe HoldRecallsController do
  let(:hold_recall) { create(:hold_recall) }
  let(:normal_params) do
    { item_id: '1234', barcode: '36105212925395', origin: 'GREEN', origin_location: 'STACKS', destination: 'GREEN' }
  end
  before do
    allow(controller).to receive_messages(current_user: user)
  end
  describe 'new' do
    let(:user) { create(:anon_user) }
    it 'should be accessible by anonymous users' do
      get :new, normal_params
      expect(response).to be_success
    end
    it 'should set defaults' do
      get :new, normal_params
      expect(assigns[:request].origin).to eq 'GREEN'
      expect(assigns[:request].origin_location).to eq 'STACKS'
      expect(assigns[:request].item_id).to eq '1234'
      expect(assigns[:request].needed_date).to eq Time.zone.today + 1.year
    end
    it 'should raise an error if the item is unmediateable' do
      expect(
        lambda do
          get :new, item_id: '1234', origin: 'GREEN', origin_location: 'STACKS', destination: 'ART'
        end
      ).to raise_error(HoldRecallsController::NotHoldRecallableError)
    end
  end
  describe 'create' do
    describe 'by anonymous users' do
      let(:user) { create(:anon_user) }
      it 'should redirect to the login page passing a refferrer param to continue creating the hold recall request' do
        post :create, request: normal_params
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

      it 'should not be allowed if user name and email is filled out' do
        expect(
          lambda do
            put :create, request: normal_params.merge(
              user_attributes: {
                name: 'Jane Stanford',
                email: 'jstanford@stanford.edu'
              }
            )
          end
        ).to raise_error(CanCan::AccessDenied)
      end
      it 'should be allowed if the library ID field is filled out' do
        put :create, request: {
          item_id: '1234',
          origin: 'SPEC-COLL',
          origin_location: 'STACKS',
          destination: 'SPEC-COLL',
          user_attributes: { library_id: '12345' }
        }

        expect(response.location).to match(/#{successful_hold_recall_url(HoldRecall.last)}\?token=/)
        expect(User.last.library_id).to eq '12345'
        expect(HoldRecall.last.user).to eq User.last
      end
      describe 'via get' do
        it 'should raise an error' do
          expect(
            lambda do
              get :create, request: normal_params
            end
          ).to raise_error(CanCan::AccessDenied)
        end
      end
    end
    describe 'by webauth users' do
      let(:user) { create(:webauth_user) }
      it 'should be allowed' do
        post :create, request: normal_params
        expect(response).to redirect_to successful_hold_recall_path(HoldRecall.last)
        expect(HoldRecall.last.origin).to eq 'GREEN'
        expect(HoldRecall.last.user).to eq user
      end

      it 'sets a default needed_date if one is not present' do
        post :create, request: normal_params
        expect(HoldRecall.last.needed_date).to eq Time.zone.today + 1.year
      end

      it 'accepts a set needed_date when provided' do
        post :create, request: normal_params.merge(needed_date: Time.zone.today + 1.month)
        expect(HoldRecall.last.needed_date).to eq Time.zone.today + 1.month
      end

      it 'does not send a confirmation email' do
        stub_symphony_response(build(:symphony_page_with_single_item))
        expect(
          lambda do
            put :create, request: normal_params
          end
        ).not_to change { ConfirmationMailer.deliveries.count }
      end

      # Note:  cannot trigger activejob from this spec to check ApprovalStatusMailer
    end
    describe 'invalid requests' do
      let(:user) { create(:webauth_user) }
      it 'should return an error message to the user' do
        post :create, request: { item_id: '1234' }
        expect(flash[:error]).to eq 'There was a problem creating your request.'
        expect(response).to render_template 'new'
      end
    end
  end

  describe '#current_request' do
    let(:user) { create(:anon_user) }
    it 'returns a HoldRecall object' do
      get :new, normal_params
      expect(controller.send(:current_request)).to be_a(HoldRecall)
    end
  end
end

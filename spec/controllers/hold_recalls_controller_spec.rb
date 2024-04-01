# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HoldRecallsController do
  let(:hold_recall) { create(:hold_recall) }
  let(:normal_params) do
    { item_id: '1234', barcode: '36105212925395', origin: 'SAL3', origin_location: 'SAL3-STACKS', destination: 'GREEN' }
  end

  before do
    allow(controller).to receive_messages(current_user: user)
    stub_bib_data_json(build(:multiple_holdings))
  end

  describe 'new' do
    let(:user) { create(:anon_user) }

    it 'is accessible by anonymous users' do
      get :new, params: normal_params
      expect(response).to be_successful
    end

    it 'sets defaults' do
      get :new, params: normal_params
      expect(assigns[:request].origin).to eq 'SAL3'
      expect(assigns[:request].origin_location).to eq 'SAL3-STACKS'
      expect(assigns[:request].item_id).to eq '1234'
      expect(assigns[:request].needed_date).to eq Time.zone.today + 1.year
    end

    it 'raises an error if the item is not provided' do
      expect do
        get :new, params: { item_id: '1234', origin: 'SAL3', origin_location: 'SAL3-STACKS', destination: 'ART' }
      end.to raise_error(HoldRecallsController::NotHoldRecallableError)
    end
  end

  describe 'create' do
    describe 'by sso users' do
      let(:user) { create(:sso_user) }
      let(:patron) do
        instance_double(Folio::Patron, id: nil, exists?: true, email: nil, patron_group_name: 'faculty',
                                       patron_group_id: 'bdc2b6d4-5ceb-4a12-ab46-249b9a68473e',
                                       ilb_eligible?: true)
      end

      before do
        allow(Settings.ils.patron_model.constantize).to receive(:find_by).with(sunetid: user.sunetid).and_return(patron)
      end

      it 'is allowed' do
        post :create, params: { request: normal_params }
        expect(response).to redirect_to successful_hold_recall_path(HoldRecall.last)
        expect(HoldRecall.last.origin).to eq 'SAL3'
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

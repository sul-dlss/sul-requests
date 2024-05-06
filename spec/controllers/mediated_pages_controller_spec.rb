# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MediatedPagesController do
  let(:mediated_page) { create(:mediated_page) }
  let(:normal_params) do
    { item_id: '1234', origin: 'ART', origin_location: 'ART-LOCKED-LARGE', destination: 'ART' }
  end

  before do
    allow(controller).to receive_messages(current_user: user)
    allow_any_instance_of(PagingSchedule::Scheduler).to receive(:valid?).with(anything).and_return(true)
    stub_bib_data_json(build(:searchable_holdings))
  end

  describe 'update' do
    let(:user) { create(:superadmin_user) }
    let!(:mediated_page) { create(:mediated_page, barcodes: ['12345678'], bib_data: build(:single_mediated_holding)) }

    before do
      stub_bib_data_json(build(:single_mediated_holding))
    end

    context 'when successful' do
      it 'returns the json representation of the updated request' do
        expect(mediated_page).not_to be_marked_as_done
        patch :update, params: { id: mediated_page.id, request: { approval_status: 'marked_as_done' } }, format: :json

        expect(mediated_page.reload).to be_marked_as_done
        expect(response.parsed_body['id']).to eq mediated_page.id
      end
    end

    context 'when unsuccessful' do
      before do
        expect_any_instance_of(MediatedPage).to receive(:update).and_return(false)
      end

      it 'returns an error status code' do
        patch :update, params: { id: mediated_page.id, request: { marked_as_complete: 'true' } }, format: :json

        expect(response).not_to be_successful
        expect(response).to have_http_status :bad_request
      end

      it 'returns a small json error message' do
        patch :update, params: { id: mediated_page.id, request: { marked_as_complete: 'true' } }, format: :json

        expect(response.parsed_body).to eq('status' => 'error')
      end
    end

    context 'by a user who cannot manage the request (even if they created the reqeust)' do
      let(:user) { create(:sso_user) }
      let!(:mediated_page) { create(:mediated_page, user:) }

      it 'renders forbidden' do
        patch :update, params: { id: mediated_page.id, request: { marked_as_complete: 'true' } }, format: :js
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end

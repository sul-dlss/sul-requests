# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MediatedPagesController do
  let(:mediated_page) { create(:mediated_page) }
  let(:normal_params) do
    { item_id: '1234', origin: 'ART', origin_location: 'ARTLCKL', destination: 'ART' }
  end

  before do
    allow(controller).to receive_messages(current_user: user)
    allow_any_instance_of(PagingSchedule::Scheduler).to receive(:valid?).with(anything).and_return(true)
  end

  describe 'new' do
    let(:user) { create(:anon_user) }

    it 'is accessible by anonymous users' do
      get :new, params: normal_params
      expect(response).to be_successful
    end

    it 'sets defaults' do
      get :new, params: normal_params
      expect(assigns[:request].origin).to eq 'ART'
      expect(assigns[:request].origin_location).to eq 'ARTLCKL'
      expect(assigns[:request].item_id).to eq '1234'
    end

    it 'raises an error if the item is unmediateable' do
      expect do
        get :new, params: { item_id: '1234', origin: 'GREEN', origin_location: 'STACKS', destination: 'ART' }
      end.to raise_error(MediatedPagesController::UnmediateableItemError)
    end
  end

  describe 'create' do
    describe 'by anonymous users' do
      let(:user) { create(:anon_user) }

      it 'redirects to the login page passing a referrer param to continue creating the mediated page request' do
        post :create, params: {
          request: {
            item_id: '1234', origin: 'ART', origin_location: 'ARTLCKL', destination: 'ART'
          }
        }
        expect(response).to redirect_to(
          login_path(
            referrer: interstitial_path(
              redirect_to: create_mediated_pages_url(
                request: {
                  item_id: '1234', origin: 'ART', origin_location: 'ARTLCKL', destination: 'ART'
                }
              )
            )
          )
        )
      end

      it 'is allowed if user name and email is filled out (via token)' do
        put :create, params: {
          request: {
            item_id: '1234',
            origin: 'ART',
            origin_location: 'ARTLCKL',
            destination: 'ART',
            needed_date: Time.zone.today + 1.year,
            user_attributes: { name: 'Jane Stanford', email: 'jstanford@stanford.edu' }
          }
        }

        expect(response.location).to match(/#{successful_mediated_page_url(MediatedPage.last)}\?token=/)
        expect(MediatedPage.last.user).to eq User.last
      end

      it 'is allowed if the library ID field is filled out' do
        allow(Symphony::Patron).to receive(:find_by).with(library_id: '12345').and_return(
          instance_double(Symphony::Patron, email: nil, exists?: true)
        )

        put :create, params: {
          request: {
            item_id: '1234',
            origin: 'ART',
            origin_location: 'ARTLCKL',
            destination: 'ART',
            needed_date: Time.zone.today + 1.year,
            user_attributes: { library_id: '12345' }
          }
        }

        expect(response.location).to match(/#{successful_mediated_page_url(MediatedPage.last)}\?token=/)
        expect(User.last.library_id).to eq '12345'
        expect(MediatedPage.last.user).to eq User.last
      end

      describe 'via get' do
        it 'raises an error' do
          expect do
            get :create, params: {
              request: {
                item_id: '1234', origin: 'ART', origin_location: 'ARTLCKL', destination: 'ART'
              }
            }
          end.to raise_error(CanCan::AccessDenied)
        end
      end
    end

    describe 'by sso users' do
      let(:user) { create(:sso_user) }

      it 'is allowed' do
        post :create, params: {
          request: {
            item_id: '1234',
            origin: 'ART',
            origin_location: 'ARTLCKL',
            destination: 'ART',
            needed_date: Time.zone.today + 1.year
          }
        }
        expect(response).to redirect_to successful_mediated_page_path(MediatedPage.last)
        expect(MediatedPage.last.origin).to eq 'ART'
        expect(MediatedPage.last.user).to eq user
      end

      it 'sends a confirmation email to the user' do
        expect do
          put :create, params: {
            request: {
              item_id: '1234',
              origin: 'ART',
              origin_location: 'ARTLCKL',
              destination: 'ART',
              needed_date: Time.zone.today + 1.year
            }
          }
        end.to change { RequestStatusMailer.deliveries.count { |x| x.subject != 'New request needs mediation' } }.by(1)
      end

      it 'sends an email to the mediator' do
        mediator_contact_info = { 'ART' => { email: 'someone@example.com' } }
        allow(Rails.application.config).to receive(:mediator_contact_info).and_return(mediator_contact_info)
        expect do
          put :create, params: {
            request: {
              item_id: '1234',
              origin: 'ART',
              origin_location: 'ARTLCKL',
              destination: 'ART',
              needed_date: Time.zone.today + 1.year
            }
          }
        end.to change { MediationMailer.deliveries.count { |x| x.subject == 'New request needs mediation' } }.by(1)
      end
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

  describe 'update' do
    let(:user) { create(:superadmin_user) }
    let!(:mediated_page) { create(:mediated_page) }

    context 'when successful' do
      it 'returns the json representation of the updated request' do
        expect(mediated_page).not_to be_marked_as_done
        patch :update, params: { id: mediated_page.id, mediated_page: { approval_status: 'marked_as_done' } }, format: :json

        expect(mediated_page.reload).to be_marked_as_done
        expect(response.parsed_body['id']).to eq mediated_page.id
      end
    end

    context 'when unsuccessful' do
      before do
        expect_any_instance_of(MediatedPage).to receive(:update).and_return(false)
      end

      it 'returns an error status code' do
        patch :update, params: { id: mediated_page.id, mediated_page: { marked_as_complete: 'true' } }, format: :json

        expect(response).not_to be_successful
        expect(response).to have_http_status :bad_request
      end

      it 'returns a small json error message' do
        patch :update, params: { id: mediated_page.id, mediated_page: { marked_as_complete: 'true' } }, format: :json

        expect(response.parsed_body).to eq('status' => 'error')
      end
    end

    context 'by a user who cannot manage the request (even if they created the reqeust)' do
      let(:user) { create(:sso_user) }
      let!(:mediated_page) { create(:mediated_page, user:) }

      it 'throws an access denied error' do
        expect do
          patch :update, params: { id: mediated_page.id, mediated_page: { marked_as_complete: 'true' } }, format: :js
        end.to raise_error(CanCan::AccessDenied)
      end
    end
  end

  describe '#current_request' do
    let(:user) { create(:anon_user) }

    it 'returns a MediatedPage object' do
      get :new, params: normal_params
      expect(controller.send(:current_request)).to be_a(MediatedPage)
    end
  end
end

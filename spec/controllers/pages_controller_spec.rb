# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PagesController do
  let(:normal_params) do
    { item_id: '1234', origin: 'SAL3', origin_location: 'SAL3-STACKS', destination: 'ART' }
  end

  before do
    allow(controller).to receive_messages(current_user: user)
    allow(Folio::Instance).to receive(:fetch).and_return(Folio::Instance.new(id: '1234'))
    stub_bib_data_json(build(:single_holding))
  end

  describe 'new' do
    let(:user) { User.new }

    it 'is accessible by anonymous users' do
      get :new, params: normal_params
      expect(response).to be_successful
    end

    it 'sets defaults' do
      get :new, params: normal_params
      expect(assigns[:request].origin).to eq 'SAL3'
      expect(assigns[:request].origin_location).to eq 'SAL3-STACKS'
      expect(assigns[:request].item_id).to eq '1234'
    end

    it 'raises an error when the item is not pageable' do
      get :new, params: { item_id: '1234', origin: 'SPEC-COLL', origin_location: 'SPEC-SAL-STACKS', destination: 'ART' }
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'create' do
    describe 'by anonymous users' do
      let(:user) { create(:anon_user) }

      it 'redirects to the login page passing a referrer param to continue creating the page request' do
        post :create, params: {
          request: { item_id: '1234', origin: 'SAL3', origin_location: 'SAL3-STACKS', destination: 'ART' }
        }
        expect(response).to redirect_to(
          login_by_sunetid_path(
            referrer: interstitial_path(
              redirect_to: create_pages_url(
                request: { item_id: '1234', origin: 'SAL3', origin_location: 'SAL3-STACKS', destination: 'ART' }
              )
            )
          )
        )
      end

      it 'strips any unselected barcodes out of the request (to reduce request size to our auth service)' do
        post :create, params: {
          request: { item_id: '1234', origin: 'SAL3', origin_location: 'SAL3-STACKS', destination: 'ART', barcodes: {
            '12345' => '0', '54321' => '1', '56789' => '0', '98765' => '1'
          } }
        }

        expect(response).to redirect_to(
          login_by_sunetid_path(
            referrer: interstitial_path(
              redirect_to: create_pages_url(
                request: { item_id: '1234', origin: 'SAL3', origin_location: 'SAL3-STACKS', destination: 'ART', barcodes: {
                  '54321' => '1', '98765' => '1'
                } }
              )
            )
          )
        )
      end

      it 'is allowed if user name and email is filled out (via token)' do
        put :create, params: {
          request: {
            item_id: '1234',
            origin: 'SAL3',
            origin_location: 'SAL3-STACKS',
            destination: 'ART',
            user_attributes: { name: 'Jane Stanford', email: 'jstanford@stanford.edu' }
          }
        }

        expect(response.location).to match(/#{successful_page_url(Page.last)}\?token=/)
        expect(Page.last.user).to eq User.last
      end

      it 'is allowed if the library ID field is filled out' do
        allow(Settings.ils.patron_model.constantize).to receive(:find_by).with(library_id: '12345').and_return(
          instance_double(Folio::Patron, id: nil, email: nil, exists?: true, patron_group_name: 'visitor')
        )

        put :create, params: {
          request: {
            item_id: '1234',
            origin: 'SAL3',
            origin_location: 'SAL3-STACKS',
            destination: 'ART',
            user_attributes: { library_id: '12345' }
          }
        }

        expect(response.location).to match(/#{successful_page_url(Page.last)}\?token=/)
        expect(User.last.library_id).to eq '12345'
        expect(Page.last.user).to eq User.last
      end

      context 'for faculty with a sponsored proxy group' do
        let(:user) do
          build(:sso_user).tap do |u|
            allow(u).to receive(:sponsor?).and_return(true)
          end
        end

        it 'prompts the user to decide whether the request should be for the proxy' do
          put :create, params: {
            request: {
              item_id: '1234',
              origin: 'SAL3',
              origin_location: 'SAL3-STACKS',
              destination: 'ART'
            }
          }

          expect(response).to render_template('proxy_request')
        end

        it 'prompts the user to decide whether the request should be for the proxy' do
          put :create, params: {
            request: {
              item_id: '1234',
              origin: 'SAL3',
              origin_location: 'SAL3-STACKS',
              destination: 'ART',
              proxy: 'true'
            }
          }

          expect(response.location).to eq successful_page_url(Page.last)
          expect(Page.last.user).to eq User.last
        end

        it 'prompts the user to decide whether the request should be for the proxy' do
          put :create, params: {
            request: {
              item_id: '1234',
              origin: 'SAL3',
              origin_location: 'SAL3-STACKS',
              destination: 'ART',
              proxy: 'false'
            }
          }

          expect(response.location).to eq successful_page_url(Page.last)
          expect(Page.last.user).to eq User.last
        end
      end

      describe 'via get' do
        it 'is forbidden' do
          get :create, params: {
            request: { item_id: '1234', origin: 'SAL3', origin_location: 'SAL3-STACKS', destination: 'ART' }
          }
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    describe 'by sso users' do
      let(:user) { create(:sso_user) }

      it 'is allowed' do
        post :create, params: {
          request: { item_id: '1234', origin: 'SAL3', origin_location: 'SAL3-STACKS', destination: 'ART' }
        }
        expect(response).to redirect_to successful_page_path(Page.last)
        expect(Page.last.origin).to eq 'SAL3'
        expect(Page.last.user).to eq user
      end

      it 'maps checkbox style barcodes correctly' do
        stub_bib_data_json(build(:multiple_holdings))

        put :create, params: {
          request: {
            item_id: '1234',
            origin: 'SAL3',
            origin_location: 'SAL3-STACKS',
            destination: 'ART',
            barcodes: { '3610512345678' => '1', '3610587654321' => '0', '12345679' => '1' }
          }
        }
        expect(response).to redirect_to successful_page_path(Page.last)
        expect(Page.last.barcodes.sort).to eq(%w(12345679 3610512345678))
      end

      it 'redirects to success page with token when the sso user supplies a library ID' do
        allow(Settings.ils.patron_model.constantize).to receive(:find_by).with(library_id: '5432123').and_return(
          instance_double(Folio::Patron, id: nil, email: nil, exists?: true, patron_group_name: 'faculty')
        )

        post :create, params: {
          request: {
            item_id: '1234',
            origin: 'SAL3',
            origin_location: 'SAL3-STACKS',
            destination: 'ART',
            user_attributes: { library_id: '5432123' }
          }
        }

        expect(response.location).to match(/#{successful_page_url(Page.last)}\?token=/)
        expect(Page.last.user.library_id).to eq '5432123'
      end

      # NOTE: cannot trigger activejob from this spec to check RequestStatusMailer

      context 'create/update' do
        let(:page) { create(:page, barcodes: ['12345678']) }

        it 'raises an error when the honey-pot email field is filled in on create' do
          expect do
            post :create, params: { request: normal_params, email: 'something' }
          end.to raise_error(RequestsController::HoneyPotFieldError)
        end

        it 'raises an error when the honey-pot email field is filled in on update' do
          expect do
            put :update, params: { id: page[:id], email: 'something' }
          end.to raise_error(RequestsController::HoneyPotFieldError)
        end
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
    let(:page) { create(:page, barcodes: ['12345678']) }

    describe 'by anonymous users' do
      let(:user) { create(:anon_user) }

      it 'is forbidden' do
        put :update, params: { id: page[:id], request: { origin: 'GREEN' } }
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'invalid requests' do
      let(:user) { create(:superadmin_user) }

      before do
        allow_any_instance_of(page.class).to receive(:update).with({}).and_return(false)
      end

      it 'returns an error message to the user' do
        put :update, params: { id: page[:id], request: { item_id: nil } }
        expect(flash[:error]).to eq 'There was a problem updating your request.'
        expect(response).to render_template 'edit'
      end
    end

    describe 'by sso users' do
      let(:user) { create(:sso_user) }

      it 'is forbidden' do
        put(:update, params: { id: page[:id] })
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'by superadmins' do
      let(:user) { create(:superadmin_user) }
      let(:page) { create(:page, barcodes: ['12345678']) }

      it 'is allowed to modify page rqeuests' do
        put :update, params: { id: page[:id], request: { needed_date: Time.zone.today + 1.day } }
        expect(flash[:success]).to eq 'Request was successfully updated.'
        expect(response).to redirect_to root_url
        expect(Page.find(page.id).needed_date.to_s).to eq((Time.zone.today + 1.day).to_s)
      end
    end
  end

  describe '#success' do
    context 'by sso users' do
      let(:user) { create(:sso_user) }

      it 'is successful if they have the are the creator of the record' do
        page = create(:page, user:)
        get :success, params: { id: page[:id] }
        expect(response).to be_successful
      end

      it 'is forbidden when the user is already authenticated but does not have access to the request' do
        page = create(:page)
        get :success, params: { id: page[:id] }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'by non-webuth users' do
      let(:user) { create(:non_sso_user) }

      it 'is forbidden' do
        page = create(:page, user: create(:non_sso_user, email: 'jjstanford@stanford.edu'))
        get :success, params: { id: page[:id] }
        expect(response).to have_http_status(:forbidden)
      end
    end
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
            referrer: status_page_url(page[:id])
          )
        )
      end
    end
  end

  describe '#current_request' do
    let(:user) { create(:anon_user) }

    it 'returns a Page object' do
      get :new, params: normal_params
      expect(controller.send(:current_request)).to be_a(Page)
    end
  end
end

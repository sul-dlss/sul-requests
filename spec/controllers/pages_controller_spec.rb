require 'rails_helper'

describe PagesController do
  let(:page) { create(:page) }
  let(:normal_params) do
    { item_id: '1234', origin: 'GREEN', origin_location: 'STACKS', destination: 'BIOLOGY' }
  end
  before do
    allow(controller).to receive_messages(current_user: user)
  end
  describe 'new' do
    let(:user) { User.new }
    it 'should be accessible by anonymous users' do
      get :new, normal_params
      expect(response).to be_success
    end
    it 'should set defaults' do
      get :new, normal_params
      expect(assigns[:request].origin).to eq 'GREEN'
      expect(assigns[:request].origin_location).to eq 'STACKS'
      expect(assigns[:request].item_id).to eq '1234'
    end
    it 'should raise an error when the item is not pageable' do
      expect(
        lambda do
          get :new, item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS', destination: 'BIOLOGY'
        end
      ).to raise_error(PagesController::UnpageableItemError)
    end
  end
  describe 'create' do
    describe 'by anonymous users' do
      let(:user) { create(:anon_user) }
      it 'should redirect to the login page passing a referrer param to continue creating the page request' do
        post :create, request: { item_id: '1234', origin: 'GREEN', origin_location: 'STACKS', destination: 'BIOLOGY' }
        expect(response).to redirect_to(
          login_path(
            referrer: create_pages_path(
              request: { item_id: '1234', origin: 'GREEN', origin_location: 'STACKS', destination: 'BIOLOGY' }
            )
          )
        )
      end
      it 'should be allowed if user name and email is filled out (via token)' do
        put :create, request: {
          item_id: '1234',
          origin: 'GREEN',
          origin_location: 'STACKS',
          destination: 'BIOLOGY',
          user_attributes: { name: 'Jane Stanford', email: 'jstanford@stanford.edu' }
        }

        expect(response.location).to match(/#{successful_page_url(Page.last)}\?token=/)
        expect(Page.last.user).to eq User.last
      end
      it 'should be allowed if the library ID field is filled out' do
        put :create, request: {
          item_id: '1234',
          origin: 'GREEN',
          origin_location: 'STACKS',
          destination: 'BIOLOGY',
          user_attributes: { library_id: '12345' }
        }

        expect(response.location).to match(/#{successful_page_url(Page.last)}\?token=/)
        expect(User.last.library_id).to eq '12345'
        expect(Page.last.user).to eq User.last
      end
      context 'for faculty with a sponsored proxy group' do
        let(:user) do
          build(:webauth_user).tap do |u|
            allow(u).to receive(:sponsor?).and_return(true)
          end
        end

        it 'prompts the user to decide whether the request should be for the proxy' do
          put :create, request: {
            item_id: '1234',
            origin: 'GREEN',
            origin_location: 'STACKS',
            destination: 'BIOLOGY'
          }

          expect(response).to render_template('sponsor_request')
        end

        it 'prompts the user to decide whether the request should be for the proxy' do
          put :create, request: {
            item_id: '1234',
            origin: 'GREEN',
            origin_location: 'STACKS',
            destination: 'BIOLOGY',
            proxy: 'true'
          }

          expect(response.location).to eq successful_page_url(Page.last)
          expect(Page.last.user).to eq User.last
        end

        it 'prompts the user to decide whether the request should be for the proxy' do
          put :create, request: {
            item_id: '1234',
            origin: 'GREEN',
            origin_location: 'STACKS',
            destination: 'BIOLOGY',
            proxy: 'false'
          }

          expect(response.location).to eq successful_page_url(Page.last)
          expect(Page.last.user).to eq User.last
        end
      end

      describe 'via get' do
        it 'should raise an error' do
          expect(
            lambda do
              get :create, request: {
                item_id: '1234', origin: 'GREEN', origin_location: 'STACKS', destination: 'BIOLOGY'
              }
            end
          ).to raise_error(CanCan::AccessDenied)
        end
      end
    end
    describe 'by webauth users' do
      let(:user) { create(:webauth_user) }
      it 'should be allowed' do
        post :create, request: { item_id: '1234', origin: 'GREEN', origin_location: 'STACKS', destination: 'BIOLOGY' }
        expect(response).to redirect_to successful_page_path(Page.last)
        expect(Page.last.origin).to eq 'GREEN'
        expect(Page.last.user).to eq user
      end
      it 'should map checkbox style barcodes correctly' do
        stub_searchworks_api_json(build(:multiple_holdings))
        put :create, request: {
          item_id: '1234',
          origin: 'GREEN',
          origin_location: 'STACKS',
          destination: 'BIOLOGY',
          barcodes: { '3610512345678' => '1', '3610587654321' => '0', '12345679' => '1' }
        }
        expect(response).to redirect_to successful_page_path(Page.last)
        expect(Page.last.barcodes).to eq(%w(3610512345678 12345679))
      end
      it 'sends an confirmation email' do
        expect(
          lambda do
            put :create, request: {
              item_id: '1234',
              origin: 'GREEN',
              origin_location: 'STACKS',
              destination: 'BIOLOGY'
            }
          end
        ).to change { ConfirmationMailer.deliveries.count }.by(1)
      end

      context 'create/update' do
        it 'raises an error when the honey-pot email field is filled in on create' do
          expect(
            lambda do
              post :create, request: normal_params, email: 'something'
            end
          ).to raise_error(RequestsController::HoneyPotFieldError)
        end

        it 'raises an error when the honey-pot email field is filled in on update' do
          expect(
            lambda do
              put :update, id: page[:id], email: 'something'
            end
          ).to raise_error(RequestsController::HoneyPotFieldError)
        end
      end
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
  describe 'update' do
    describe 'by anonymous users' do
      let(:user) { create(:anon_user) }
      it 'should raise an error' do
        expect(-> { put :update, id: page[:id], request: { origin: 'GREEN' } }).to raise_error(CanCan::AccessDenied)
      end
    end
    describe 'invalid requests' do
      let(:user) { create(:superadmin_user) }
      before do
        allow_any_instance_of(page.class).to receive(:update).with({}).and_return(false)
      end
      it 'should return an error message to the user' do
        put :update, id: page[:id], request: { item_id: nil }
        expect(flash[:error]).to eq 'There was a problem updating your request.'
        expect(response).to render_template 'edit'
      end
    end
    describe 'by webauth users' do
      let(:user) { create(:webauth_user) }
      it 'should raise an error' do
        expect(-> { put(:update, id: page[:id]) }).to raise_error(CanCan::AccessDenied)
      end
    end
    describe 'by superadmins' do
      let(:user) { create(:superadmin_user) }
      it 'should be allowed to modify page rqeuests' do
        put :update, id: page[:id], request: { needed_date: '2015-04-14' }
        expect(flash[:success]).to eq 'Request was successfully updated.'
        expect(response).to redirect_to root_url
        expect(Page.find(page.id).needed_date.to_s).to eq '2015-04-14'
      end
    end
  end

  describe '#current_request' do
    let(:user) { create(:anon_user) }
    it 'returns a Page object' do
      get :new, normal_params
      expect(controller.send(:current_request)).to be_a(Page)
    end
  end
end

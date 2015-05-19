require 'rails_helper'

describe MediatedPagesController do
  let(:mediated_page) { create(:mediated_page) }
  let(:normal_params) do
    { item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS', destination: 'SPEC-COLL' }
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
      expect(assigns[:mediated_page].origin).to eq 'SPEC-COLL'
      expect(assigns[:mediated_page].origin_location).to eq 'STACKS'
      expect(assigns[:mediated_page].item_id).to eq '1234'
    end
    it 'should raise an error if the item is unmediateable' do
      expect(
        lambda do
          get :new, item_id: '1234', origin: 'GREEN', origin_location: 'STACKS', destination: 'BIOLOGY'
        end
      ).to raise_error(MediatedPagesController::UnmediateableItemError)
    end
  end
  describe 'create' do
    describe 'by anonymous users' do
      let(:user) { create(:anon_user) }
      it 'should redirect to the login page passing a refferrer param to continue creating the mediated page request' do
        post :create, mediated_page: {
          item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS', destination: 'SPEC-COLL'
        }
        expect(response).to redirect_to(
          login_path(
            referrer: create_mediated_pages_path(
              page: { item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS', destination: 'SPEC-COLL' }
            )
          )
        )
      end
      it 'should be allowed if user name and email is filled out (via token)' do
        put :create, mediated_page: {
          item_id: '1234',
          origin: 'SPEC-COLL',
          origin_location: 'STACKS',
          destination: 'SPEC-COLL',
          user_attributes: { name: 'Jane Stanford', email: 'jstanford@stanford.edu' }
        }

        expect(response.location).to match(/#{successful_mediated_page_url(MediatedPage.last)}\?token=/)
        expect(MediatedPage.last.user).to eq User.last
      end
      it 'should be allowed if the library ID field is filled out' do
        put :create, mediated_page: {
          item_id: '1234',
          origin: 'SPEC-COLL',
          origin_location: 'STACKS',
          destination: 'SPEC-COLL',
          user_attributes: { library_id: '12345' }
        }

        expect(response.location).to match(/#{successful_mediated_page_url(MediatedPage.last)}\?token=/)
        expect(User.last.library_id).to eq '12345'
        expect(MediatedPage.last.user).to eq User.last
      end
      describe 'for HOPKINS' do
        it 'should not be by library ID' do
          expect(
            lambda do
              put :create, mediated_page: {
                item_id: '1234',
                origin: 'HOPKINS',
                origin_location: 'STACKS',
                destination: 'GREEN',
                user_attributes: { library_id: '12345' }
              }
            end
          ).to raise_error(CanCan::AccessDenied)
        end
        it 'should not be by name and email' do
          expect(
            lambda do
              put :create, mediated_page: {
                item_id: '1234',
                origin: 'HOPKINS',
                origin_location: 'STACKS',
                destination: 'GREEN',
                user_attributes: { name: 'Jane Stanford', email: 'jstanford@stanford.edu' }
              }
            end
          ).to raise_error(CanCan::AccessDenied)
        end
      end
      describe 'via get' do
        it 'should raise an error' do
          expect(
            lambda do
              get :create, mediated_page: {
                item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS', destination: 'SPEC-COLL'
              }
            end
          ).to raise_error(CanCan::AccessDenied)
        end
      end
    end
    describe 'by webauth users' do
      let(:user) { create(:webauth_user) }
      it 'should be allowed' do
        post :create, mediated_page: {
          item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS', destination: 'SPEC-COLL'
        }
        expect(response).to redirect_to successful_mediated_page_path(MediatedPage.last)
        expect(MediatedPage.last.origin).to eq 'SPEC-COLL'
        expect(MediatedPage.last.user).to eq user
      end

      it 'sends an confirmation email' do
        expect(
          lambda do
            put :create, mediated_page: {
              item_id: '1234',
              origin: 'SPEC-COLL',
              origin_location: 'STACKS',
              destination: 'SPEC-COLL'
            }
          end
        ).to change { ConfirmationMailer.deliveries.count }.by(1)
      end
    end
    describe 'invalid requests' do
      let(:user) { create(:webauth_user) }
      it 'should return an error message to the user' do
        post :create, mediated_page: { item_id: '1234' }
        expect(flash[:error]).to eq 'There was a problem creating your request.'
        expect(response).to render_template 'new'
      end
    end
  end

  describe '#current_request' do
    let(:user) { create(:anon_user) }
    it 'returns a MediatedPage object' do
      expect(controller.send(:current_request)).to be_a(MediatedPage)
    end
  end
end

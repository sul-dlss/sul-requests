require 'rails_helper'

describe MediatedPagesController do
  let(:mediated_page) { create(:mediated_page) }
  let(:normal_params) do
    { item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS', destination: 'SPEC-COLL' }
  end
  before do
    allow(controller).to receive_messages(current_user: user)
  end

  before do
    allow_any_instance_of(PagingSchedule::Scheduler).to receive(:valid?).with(anything).and_return(true)
  end

  describe 'new' do
    let(:user) { create(:anon_user) }
    it 'should be accessible by anonymous users' do
      get :new, normal_params
      expect(response).to be_success
    end
    it 'should set defaults' do
      get :new, normal_params
      expect(assigns[:request].origin).to eq 'SPEC-COLL'
      expect(assigns[:request].origin_location).to eq 'STACKS'
      expect(assigns[:request].item_id).to eq '1234'
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
      it 'should redirect to the login page passing a referrer param to continue creating the mediated page request' do
        post :create, request: {
          item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS', destination: 'SPEC-COLL'
        }
        expect(response).to redirect_to(
          login_path(
            referrer: interstitial_path(
              redirect_to: create_mediated_pages_url(
                request: {
                  item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS', destination: 'SPEC-COLL'
                }
              )
            )
          )
        )
      end
      it 'should be allowed if user name and email is filled out (via token)' do
        put :create, request: {
          item_id: '1234',
          origin: 'SPEC-COLL',
          origin_location: 'STACKS',
          destination: 'SPEC-COLL',
          needed_date: Time.zone.today + 1.year,
          user_attributes: { name: 'Jane Stanford', email: 'jstanford@stanford.edu' }
        }

        expect(response.location).to match(/#{successful_mediated_page_url(MediatedPage.last)}\?token=/)
        expect(MediatedPage.last.user).to eq User.last
      end
      it 'should be allowed if the library ID field is filled out' do
        put :create, request: {
          item_id: '1234',
          origin: 'SPEC-COLL',
          origin_location: 'STACKS',
          destination: 'SPEC-COLL',
          needed_date: Time.zone.today + 1.year,
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
              put :create, request: {
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
              put :create, request: {
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
              get :create, request: {
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
        post :create, request: {
          item_id: '1234',
          origin: 'SPEC-COLL',
          origin_location: 'STACKS',
          destination: 'SPEC-COLL',
          needed_date: Time.zone.today + 1.year
        }
        expect(response).to redirect_to successful_mediated_page_path(MediatedPage.last)
        expect(MediatedPage.last.origin).to eq 'SPEC-COLL'
        expect(MediatedPage.last.user).to eq user
      end

      it 'does not send an approval status email' do
        stub_symphony_response(build(:symphony_page_with_single_item))
        expect(
          lambda do
            put :create, request: {
              item_id: '1234',
              origin: 'SPEC-COLL',
              origin_location: 'STACKS',
              destination: 'SPEC-COLL',
              needed_date: Time.zone.today + 1.year
            }
          end
        ).not_to change {
          ApprovalStatusMailer.deliveries.count { |x| x.subject =~ /Your request/ }
        }
      end

      it 'sends a confirmation email to the user' do
        expect(
          lambda do
            put :create, request: {
              item_id: '1234',
              origin: 'SPEC-COLL',
              origin_location: 'STACKS',
              destination: 'SPEC-COLL',
              needed_date: Time.zone.today + 1.year
            }
          end
        ).to change { ConfirmationMailer.deliveries.count { |x| x.subject != 'New request needs mediation' } }.by(1)
      end

      it 'sends an email to the mediator' do
        mediator_contact_info = { 'SPEC-COLL' => { email: 'someone@example.com' } }
        allow(Rails.application.config).to receive(:mediator_contact_info).and_return(mediator_contact_info)
        expect(
          lambda do
            put :create, request: {
              item_id: '1234',
              origin: 'SPEC-COLL',
              origin_location: 'STACKS',
              destination: 'SPEC-COLL',
              needed_date: Time.zone.today + 1.year
            }
          end
        ).to change { MediationMailer.deliveries.count { |x| x.subject == 'New request needs mediation' } }.by(1)
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
    let(:user) { create(:superadmin_user) }
    let!(:mediated_page) { create(:mediated_page) }

    context 'when successful' do
      it 'returns the json representation of the updated request' do
        expect(mediated_page).to_not be_marked_as_done
        patch :update, id: mediated_page.id, mediated_page: { approval_status: 'marked_as_done' }, format: :js

        expect(mediated_page.reload).to be_marked_as_done
        expect(JSON.parse(response.body)['id']).to eq mediated_page.id
      end
    end

    context 'when unsuccesful' do
      before do
        expect_any_instance_of(MediatedPage).to receive(:update).and_return(false)
      end

      it 'returns an error status code' do
        patch :update, id: mediated_page.id, mediated_page: { marked_as_complete: 'true' }, format: :js

        expect(response).not_to be_success
        expect(response.status).to eq 400
      end

      it 'returns a small json error message' do
        patch :update, id: mediated_page.id, mediated_page: { marked_as_complete: 'true' }, format: :js

        expect(JSON.parse(response.body)).to eq('status' => 'error')
      end
    end

    context 'by a user who cannot manage the request (even if they created the reqeust)' do
      let(:user) { create(:webauth_user) }
      let!(:mediated_page) { create(:mediated_page, user: user) }

      it 'throws an access denied error' do
        expect(
          lambda do
            patch :update, id: mediated_page.id, mediated_page: { marked_as_complete: 'true' }, format: :js
          end
        ).to raise_error(CanCan::AccessDenied)
      end
    end
  end

  describe '#current_request' do
    let(:user) { create(:anon_user) }
    it 'returns a MediatedPage object' do
      get :new, normal_params
      expect(controller.send(:current_request)).to be_a(MediatedPage)
    end
  end
end

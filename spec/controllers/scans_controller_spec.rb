require 'rails_helper'

describe ScansController do
  before do
    stub_searchworks_api_json(build(:sal3_holdings))
  end
  let(:scan) { create(:scan_with_holdings, origin: 'SAL3', origin_location: 'STACKS', barcodes: ['12345678']) }
  let(:scannable_params) do
    { item_id: '12345', origin: 'SAL3', origin_location: 'STACKS' }
  end
  before do
    allow(controller).to receive_messages(current_user: user)
  end
  describe 'new' do
    let(:user) { create(:anon_user) }
    it 'should be accessible by anonymous users' do
      get :new, scannable_params
      expect(response).to be_success
    end
    it 'should set defaults' do
      get :new, scannable_params
      expect(assigns[:scan].origin).to eq 'SAL3'
      expect(assigns[:scan].origin_location).to eq 'STACKS'
      expect(assigns[:scan].item_id).to eq '12345'
    end
    it 'should raise an error when an unscannable item is requested' do
      expect(
        -> { get :new, item_id: '12345', origin: 'SAL1/2', origin_location: 'STACKS' }
      ).to raise_error(ScansController::UnscannableItemError)
    end
  end
  describe 'create' do
    describe 'by anonymous users' do
      let(:user) { create(:anon_user) }
      it 'should redirect to the login page passing a refferrer param to continue creating the scan request' do
        post :create, scan: { item_id: '12345', origin: 'GREEN', origin_location: 'STACKS' }
        expect(response).to redirect_to(
          login_path(
            referrer: create_scans_path(
              scan: { item_id: '12345', origin: 'GREEN', origin_location: 'STACKS' }
            )
          )
        )
      end
      it 'should not be allowed by users that only supply name and email' do
        expect(
          lambda do
            put :create, scan: {
              item_id: '12345',
              origin: 'SAL3',
              origin_location: 'STACKS',
              user_attributes: { name: 'Jane Stanford', email: 'jstanford@stanford.edu' }
            }
          end
        ).to raise_error(CanCan::AccessDenied)
      end
      it 'should not be allowed by users that only supply a library id' do
        expect(
          lambda do
            put :create, scan: {
              item_id: '12345',
              origin: 'SAL3',
              origin_location: 'STACKS',
              user_attributes: { library_id: '12345' }
            }
          end
        ).to raise_error(CanCan::AccessDenied)
      end
      describe 'via get' do
        it 'should raise an error' do
          expect(
            -> { get :create, scan: { item_id: '12345', origin: 'GREEN', origin_location: 'STACKS' } }
          ).to raise_error(CanCan::AccessDenied)
        end
      end
    end
    describe 'by non-webauth users' do
      let(:user) { create(:non_webauth_user) }
      it 'should raise an error' do
        expect(-> { put(:create, scan: { origin: 'SAL3' }) }).to raise_error(CanCan::AccessDenied)
      end
    end
    describe 'by webauth users' do
      let(:user) { create(:webauth_user) }
      before do
        stub_searchworks_api_json(build(:sal3_holdings))
      end
      it 'should be allowed' do
        post :create, scan: { item_id: '12345', origin: 'SAL3', origin_location: 'STACKS', barcodes: ['12345678'] }
        expect(Scan.last.origin).to eq 'SAL3'
        expect(Scan.last.user).to eq user
      end

      it 'should construct an illiad query url' do
        illiad_response = controller.send(:illiad_query, create(:scan_with_holdings, barcodes: ['12345678']))
        expect(illiad_response).to include('illiad.dll/OpenURL?')
        expect(illiad_response).to include('&rft.genre=scananddeliverArticle')
        expect(illiad_response).to include('&rft.jtitle=SAL3+Item+Title')
        expect(illiad_response).to include('&rft.volume=ABC+123')
      end

      it 'sends an confirmation email' do
        stub_searchworks_api_json(build(:sal3_holdings))
        expect(
          lambda do
            put :create, scan: {
              item_id: '12345',
              origin: 'SAL3',
              origin_location: 'STACKS',
              barcodes: ['12345678']
            }
          end
        ).to change { ConfirmationMailer.deliveries.count }.by(1)
      end
    end
    describe 'invalid requests' do
      let(:user) { create(:webauth_user) }
      it 'should return an error message to the user' do
        post :create, scan: { item_id: '12345' }
        expect(flash[:error]).to eq 'There was a problem creating your scan request.'
        expect(response).to render_template 'new'
      end
    end
  end
  describe 'update' do
    describe 'by anonymous users' do
      let(:user) { create(:anon_user) }
      it 'should raise an error' do
        expect(-> { put(:update, id: scan[:id]) }).to raise_error(CanCan::AccessDenied)
      end
    end
    describe 'invalid requests' do
      let(:user) { create(:superadmin_user) }
      before do
        allow_any_instance_of(scan.class).to receive(:update).with({}).and_return(false)
      end
      it 'should return an error message to the user' do
        put :update, id: scan[:id], scan: { item_id: nil }
        expect(flash[:error]).to eq 'There was a problem updating your scan request.'
        expect(response).to render_template 'edit'
      end
    end
    describe 'by webauth users' do
      let(:user) { create(:webauth_user) }
      it 'should raise an error' do
        expect(-> { put(:update, id: scan[:id]) }).to raise_error(CanCan::AccessDenied)
      end
    end
    describe 'by superadmins' do
      let(:user) { create(:superadmin_user) }
      it 'should be allowed to modify page rqeuests' do
        put :update, id: scan[:id], scan: { needed_date: '2015-04-14' }
        expect(response).to redirect_to root_url
        expect(flash[:success]).to eq 'Scan request was successfully updated.'
        expect(Scan.find(scan.id).needed_date.to_s).to eq '2015-04-14'
      end
    end
  end

  describe '#current_request' do
    let(:user) { create(:anon_user) }
    it 'returns a Page object' do
      expect(controller.send(:current_request)).to be_a(Scan)
    end
  end
end

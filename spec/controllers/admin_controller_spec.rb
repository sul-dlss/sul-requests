require 'rails_helper'

describe AdminController do
  before do
    allow(controller).to receive_messages(current_user: user)
  end

  describe '/admin' do
    describe 'for super admin' do
      let(:user) { create(:superadmin_user) }
      it 'should be accessible' do
        get :index
        expect(response).to be_successful
      end
    end
    describe 'for site admin' do
      let(:user) { create(:site_admin_user) }
      it 'should be accessible' do
        get :index
        expect(response).to be_successful
      end
    end
    describe 'for webauth user' do
      let(:user) { create(:webauth_user) }
      it 'should not be accessible' do
        expect(-> { get :index }).to raise_error(CanCan::AccessDenied)
      end
    end
    describe 'for non-webauth user' do
      let(:user) { create(:non_webauth_user) }
      it 'should not be accessible' do
        expect(-> { get :index }).to raise_error(CanCan::AccessDenied)
      end
    end
    describe 'for anon user' do
      let(:user) { create(:anon_user) }
      it 'should not be accessible' do
        expect(-> { get :index }).to raise_error(CanCan::AccessDenied)
      end
    end
  end
end

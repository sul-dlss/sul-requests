require 'rails_helper'

describe PagesController do
  let(:page) { Page.create(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS') }
  let(:normal_params) do
    { item_id: '1234', origin: 'GREEN', origin_location: 'STACKS' }
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
      expect(assigns[:page].origin).to eq 'GREEN'
      expect(assigns[:page].origin_location).to eq 'STACKS'
      expect(assigns[:page].item_id).to eq '1234'
    end
  end
  describe 'create' do
    describe 'by anonymous users' do
      let(:user) { User.new }
      it 'should redirect to the login page passing a refferrer param to continue creating the page request' do
        post :create, page: { item_id: '1234', origin: 'GREEN', origin_location: 'STACKS' }
        expect(response).to redirect_to(
          login_path(
            referrer: create_pages_path(
              page: { item_id: '1234', origin: 'GREEN', origin_location: 'STACKS' }
            )
          )
        )
      end
      it 'should be allowed if user name and email is filled out (via token)' do
        put :create, page: {
          item_id: '1234',
          origin: 'GREEN',
          origin_location: 'STACKS',
          user_attributes: { name: 'Jane Stanford', email: 'jstanford@stanford.edu' }
        }

        expect(response.location).to match(/#{successfull_page_url(Page.last)}\?token=/)
        expect(Page.last.user).to eq User.last
      end
      describe 'via get' do
        it 'should raise an error' do
          expect(
            -> { get :create, page: { item_id: '1234', origin: 'GREEN', origin_location: 'STACKS' } }
          ).to raise_error(CanCan::AccessDenied)
        end
      end
    end
    describe 'by webauth users' do
      let(:user) { User.create(webauth: 'some-user') }
      it 'should be allowed' do
        post :create, page: { item_id: '1234', origin: 'GREEN', origin_location: 'STACKS' }
        expect(response).to redirect_to successfull_page_path(Page.last)
        expect(Page.last.origin).to eq 'GREEN'
        expect(Page.last.user).to eq user
      end
    end
    describe 'invalid requests' do
      let(:user) { User.new(webauth: 'some-user') }
      it 'should return an error message to the user' do
        post :create, page: { item_id: '1234' }
        expect(flash[:error]).to eq 'There was a problem creating your request.'
        expect(response).to render_template 'new'
      end
    end
  end
  describe 'update' do
    describe 'by anonymous users' do
      let(:user) { User.new }
      it 'should raise an error' do
        expect(-> { put :update, id: page[:id], page: { origin: 'GREEN' } }).to raise_error(CanCan::AccessDenied)
      end
    end
    describe 'invalid requests' do
      let(:user) { User.new }
      before do
        allow(user).to receive_messages(superadmin?: true)
        allow_any_instance_of(page.class).to receive(:update).with({}).and_return(false)
      end
      it 'should return an error message to the user' do
        put :update, id: page[:id], page: { item_id: nil }
        expect(flash[:error]).to eq 'There was a problem updating your request.'
        expect(response).to render_template 'edit'
      end
    end
    describe 'by webauth users' do
      let(:user) { User.new(webauth: 'some-user') }
      it 'should raise an error' do
        expect(-> { put(:update, id: page[:id]) }).to raise_error(CanCan::AccessDenied)
      end
    end
    describe 'by superadmins' do
      let(:user) { User.new }
      before do
        allow(user).to receive_messages(superadmin?: true)
      end
      it 'should be allowed to modify page rqeuests' do
        put :update, id: page[:id], page: { needed_date: '2015-04-14' }
        expect(flash[:success]).to eq 'Request was successfully updated.'
        expect(response).to redirect_to root_url
        expect(Page.find(page.id).needed_date.to_s).to eq '2015-04-14'
      end
    end
  end
end

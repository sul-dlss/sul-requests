require 'rails_helper'

describe PagingScheduleController do
  describe 'index' do
    describe 'by anonmyous users' do
      it 'raises an error' do
        expect(-> { get :index }).to raise_error(CanCan::AccessDenied)
      end
    end

    describe 'by site admins' do
      before { stub_current_user(create(:site_admin_user)) }
      it 'assigns the paging_schedule instance variable' do
        get :index
        expect(response).to be_success
        expect(assigns(:paging_schedule)).to be_a Array
      end
    end
  end

  describe 'show' do
    describe 'when an estimate is present' do
      before do
        expect(PagingSchedule).to receive_messages(for: estimate)
      end
      let(:estimate) { double(estimate: { a: 'a', b: 'b' }) }
      it 'is accessible by anonymous users' do
        get :show, origin: 'SAL3', destination: 'GREEN'
        expect(response).to be_success
      end

      it 'returns json when requested' do
        get :show, origin: 'SAL3', destination: 'GREEN', format: 'json'
        expect(JSON.parse(response.body)).to eq('a' => 'a', 'b' => 'b')
      end

      it 'returns the estimate as a string when HTML is requested' do
        get :show, origin: 'SAL3', destination: 'GREEN', format: 'html'
        expect(response.body).to eq('{:a=>"a", :b=>"b"}')
      end
    end

    describe 'when there is no schedule found' do
      before do
        expect(PagingSchedule).to receive(:for).and_raise(PagingSchedule::ScheduleNotFound)
      end
      it 'responds with a 404 error' do
        get :show, origin: 'DOES-NOT-EXIST', destination: 'NOT-REAL'
        expect(response).to_not be_success
        expect(response.status).to be 404
      end
    end
  end
end

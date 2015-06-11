require 'rails_helper'

describe RequestsController do
  let(:scannable_params) do
    { item_id: '12345', origin: 'SAL3', origin_location: 'STACKS' }
  end
  let(:unscannable_params) do
    { item_id: '12345', origin: 'SAL1/2', origin_location: 'STACKS' }
  end
  let(:mediated_page_params) do
    { item_id: '12345', origin: 'SPEC-COLL', origin_location: 'STACKS' }
  end
  let(:hold_recall_params) do
    { item_id: '12345', barcode: '3610512345', origin: 'GREEN', origin_location: 'STACKS' }
  end
  describe '#new' do
    describe 'required parameters' do
      it 'should require an item id, library, and location' do
        expect(-> { get(:new, item_id: '1234') }).to raise_error(ActionController::ParameterMissing)
        expect(-> { get(:new, origin: 'GREEN') }).to raise_error(ActionController::ParameterMissing)
        expect(-> { get(:new, origin_location: 'STACKS') }).to raise_error(ActionController::ParameterMissing)
      end
    end

    describe 'defaults' do
      it 'should be set' do
        get :new, hold_recall_params
        expect(assigns[:request].origin).to eq 'GREEN'
        expect(assigns[:request].origin_location).to eq 'STACKS'
        expect(assigns[:request].item_id).to eq '12345'
        expect(assigns[:request].requested_barcode).to eq '3610512345'
      end
    end

    describe 'scannable item' do
      before do
        stub_searchworks_api_json(build(:sal3_holdings))
      end
      it 'should display a page to choose to have an item scanned or delivered' do
        get :new, scannable_params
        expect(response).to render_template('new')
      end
    end

    describe 'unscannable item' do
      it 'should redirect to the new mediated page request form' do
        get :new, mediated_page_params
        expect(response).to redirect_to new_mediated_page_path(mediated_page_params)
      end
    end

    describe 'unmediateable item' do
      it 'rediredcts to the new page form' do
        get :new, unscannable_params
        expect(response).to redirect_to new_page_path(unscannable_params)
      end
    end
  end

  describe 'delegated_new_request_path' do
    let(:path) { controller.send(:delegated_new_request_path, request) }
    describe 'for pages' do
      let(:request) { build(:request) }
      it 'delegeates the request object' do
        path
        expect(request.type).to eq 'Page'
      end

      it 'returns the page path' do
        expect(path).to eq new_page_path
      end
    end

    describe 'for medated pages' do
      let(:request) { create(:request, origin: 'SPEC-COLL') }
      it 'delegeates the request object' do
        path
        expect(request.type).to eq 'MediatedPage'
      end

      it 'retruns the mediated page path' do
        expect(path).to eq new_mediated_page_path
      end
    end
  end

  describe 'modify_item_selector_checkboxes' do
    it 'should raise an error of the subclassing controller does not implement the local_object_param method' do
      expect(controller.send(:modify_item_selector_checkboxes)).to be_nil
    end
  end

  describe '#current_request' do
    it 'returns a request object' do
      get :new, scannable_params
      expect(controller.send(:current_request)).to be_a(Request)
    end
  end
end

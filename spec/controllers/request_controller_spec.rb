require 'rails_helper'

describe RequestsController do
  let(:scannable_params) do
    { item_id: '12345', origin: 'SAL3', location: 'STACKS' }
  end
  let(:unscannable_params) do
    { item_id: '12345', origin: 'SAL1/2', location: 'STACKS' }
  end
  describe '#new' do
    describe 'required parameters' do
      it 'should require an item id, library, and location' do
        expect(-> { get(:new, item_id: '1234') }).to raise_error(ActionController::ParameterMissing)
        expect(-> { get(:new, origin: 'GREEN') }).to raise_error(ActionController::ParameterMissing)
        expect(-> { get(:new, location: 'STACKS') }).to raise_error(ActionController::ParameterMissing)
      end
    end
    describe 'defaults' do
      it 'should be set' do
        get :new, scannable_params
        expect(assigns[:request].origin).to eq 'SAL3'
        expect(assigns[:request].origin_location).to eq 'STACKS'
        expect(assigns[:request].item_id).to eq '12345'
      end
    end
    describe 'scannable item' do
      it 'should display a page to choose to have an item scanned or delivered' do
        get :new, scannable_params
        expect(response).to render_template('new')
      end
    end
    describe 'unscannable item' do
      it 'should redirect to the new page request form' do
        get :new, unscannable_params
        expect(response).to redirect_to new_page_path(unscannable_params)
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestsController do
  let(:scannable_params) do
    { item_id: '12345', origin: 'SAL3', origin_location: 'STACKS' }
  end
  let(:unscannable_params) do
    { item_id: '12345', origin: 'SAL1/2', origin_location: 'STACKS' }
  end
  let(:mediated_page_params) do
    { item_id: '12345', origin: 'ART', origin_location: 'ARTLCKL' }
  end
  let(:hold_recall_params) do
    { item_id: '12345', barcode: '3610512345', origin: 'GREEN', origin_location: 'STACKS' }
  end

  let(:folio_holding_response) do
    { 'instanceId' => 'f1c52ab3-721e-5234-9a00-1023e034e2e8',
      'source' => 'MARC',
      'modeOfIssuance' => 'single unit',
      'natureOfContent' => [],
      'holdings' => [],
      'items' =>
       [{ 'id' => '584baef9-ea2f-5ff5-9947-bbc348aee4a4',
          'status' => 'Available',
          'barcode' => '3610512345678',
          'location' =>
          { 'effectiveLocation' => { 'code' => 'GRE-STACKS' },
            'permanentLocation' => { 'code' => 'GRE-STACKS' },
            'temporaryLocation' => {} },
          'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
          'permanentLoanType' => 'Can circulate',
          'suppressFromDiscovery' => false },
        { 'id' => '99466f50-2b8c-51d4-8890-373190b8f6c4',
          'status' => 'Available',
          'barcode' => '12345679',
          'location' =>
          { 'effectiveLocation' => { 'code' => 'GRE-STACKS' },
            'permanentLocation' => { 'code' => 'GRE-STACKS' },
            'temporaryLocation' => {} },
          'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
          'permanentLoanType' => 'Can circulate',
          'suppressFromDiscovery' => false },
        { 'id' => 'deec4ae9-545c-5d60-85b0-b1048b9dad05',
          'status' => 'Available',
          'barcode' => '36105028330483',
          'location' =>
          { 'effectiveLocation' => { 'code' => 'GRE-STACKS' },
            'permanentLocation' => { 'code' => 'GRE-STACKS' },
            'temporaryLocation' => {} },
          'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
          'permanentLoanType' => 'Can circulate',
          'suppressFromDiscovery' => false }] }
  end

  before do
    allow_any_instance_of(FolioClient).to receive(:find_instance).and_return({ indexTitle: 'Item Title' })
    allow_any_instance_of(FolioClient).to receive(:resolve_to_instance_id).and_return('f1c52ab3-721e-5234-9a00-1023e034e2e8')
    allow_any_instance_of(FolioClient).to receive(:items_and_holdings).and_return(folio_holding_response)
  end

  describe '#new' do
    describe 'required parameters' do
      it 'item id, library, and location' do
        expect do
          get(:new, params: { item_id: '1234', origin: 'GREEN' })
        end.to raise_error(ActionController::ParameterMissing)

        expect do
          get(:new, params: { origin: 'GREEN', origin_location: 'STACKS' })
        end.to raise_error(ActionController::ParameterMissing)

        expect do
          get(:new, params: { item_id: '1234', origin_location: 'STACKS' })
        end.to raise_error(ActionController::ParameterMissing)
      end
    end

    describe 'defaults' do
      it 'are set' do
        get :new, params: hold_recall_params
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
      let(:folio_holding_response) do
        { 'instanceId' => 'f1c52ab3-721e-5234-9a00-1023e034e2e8',
          'source' => 'MARC',
          'modeOfIssuance' => 'single unit',
          'natureOfContent' => [],
          'holdings' => [],
          'items' =>
           [{ 'id' => '584baef9-ea2f-5ff5-9947-bbc348aee4a4',
              'status' => 'Available',
              'barcode' => '3610512345678',
              'location' =>
              { 'effectiveLocation' => { 'code' => 'SAL3-STACKS' },
                'permanentLocation' => { 'code' => 'SAL3-STACKS' },
                'temporaryLocation' => {} },
              'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
              'permanentLoanType' => 'Can circulate',
              'suppressFromDiscovery' => false },
            { 'id' => '99466f50-2b8c-51d4-8890-373190b8f6c4',
              'status' => 'Available',
              'barcode' => '12345679',
              'location' =>
              { 'effectiveLocation' => { 'code' => 'SAL3-STACKS' },
              'permanentLocation' => { 'code' => 'SAL3-STACKS' },
              'temporaryLocation' => {} },
              'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
              'permanentLoanType' => 'Can circulate',
              'suppressFromDiscovery' => false }] }
      end

      it 'displays a page to choose to have an item scanned or delivered' do
        get :new, params: scannable_params
        expect(response).to render_template('new')
      end
    end

    describe 'unscannable item' do
      it 'redirects to the new mediated page request form' do
        get :new, params: mediated_page_params
        expect(response).to redirect_to new_mediated_page_path(mediated_page_params)
      end
    end

    describe 'unmediateable item' do
      it 'redirects to the new page form' do
        get :new, params: unscannable_params
        expect(response).to redirect_to new_page_path(unscannable_params)
      end
    end
  end

  describe 'delegated_new_request_path' do
    let(:path) { controller.send(:delegated_new_request_path, request) }

    describe 'for pages' do
      let(:request) { build(:request) }

      it 'delegates the request object' do
        path
        expect(request.type).to eq 'Page'
      end

      it 'returns the page path' do
        expect(path).to eq new_page_path
      end
    end

    describe 'for mediated pages' do
      let(:request) { create(:request, origin: 'ART', origin_location: 'ARTLCKL') }

      it 'delegates the request object' do
        path
        expect(request.type).to eq 'MediatedPage'
      end

      it 'returns the mediated page path' do
        expect(path).to eq new_mediated_page_path
      end
    end

    describe 'for aeon pages' do
      let(:request) { create(:request, origin: 'SPEC-COLL') }

      it 'delegates the request object' do
        path
        expect(request.type).to eq 'AeonPage'
      end

      it 'returns the aeon page path' do
        expect(path).to eq new_aeon_page_path
      end
    end
  end

  describe '#current_request' do
    it 'returns a request object' do
      get :new, params: scannable_params
      expect(controller.send(:current_request)).to be_a(Request)
    end
  end

  describe '#request_params_without_user_attrs_or_unselected_barcodes' do
    it 'removes unselected barcodes' do
      expect(controller).to receive(:params).at_least(:once).and_return(
        ActionController::Parameters.new(
          request: { barcodes: { 'abc' => '1', 'cba' => '0' } }
        )
      )

      expect(controller.send(:request_params_without_user_attrs_or_unselected_barcodes).to_unsafe_h).to eq(
        'barcodes' => { 'abc' => '1' }
      )
    end

    it 'handles barcode arrays' do
      expect(controller).to receive(:params).at_least(:once).and_return(
        ActionController::Parameters.new(
          request: { barcodes: ['abc'] }
        )
      )

      expect(controller.send(:request_params_without_user_attrs_or_unselected_barcodes).to_unsafe_h).to eq(
        'barcodes' => ['abc']
      )
    end

    it 'handles the special NO_BARCODE value' do
      expect(controller).to receive(:params).at_least(:once).and_return(
        ActionController::Parameters.new(
          request: { barcodes: { 'NO_BARCODE' => '1' } }
        )
      )

      expect(controller.send(:request_params_without_user_attrs_or_unselected_barcodes).to_unsafe_h).to eq(
        'barcodes' => []
      )
    end
  end

  describe 'layout setting' do
    before do
      stub_searchworks_api_json(build(:sal3_holdings))
    end

    let(:folio_holding_response) do
      { 'instanceId' => 'f1c52ab3-721e-5234-9a00-1023e034e2e8',
        'source' => 'MARC',
        'modeOfIssuance' => 'single unit',
        'natureOfContent' => [],
        'holdings' => [],
        'items' =>
         [{ 'id' => '584baef9-ea2f-5ff5-9947-bbc348aee4a4',
            'status' => 'Available',
            'barcode' => '3610512345678',
            'location' =>
            { 'effectiveLocation' => { 'code' => 'SAL3-STACKS' },
              'permanentLocation' => { 'code' => 'SAL3-STACKS' },
              'temporaryLocation' => {} },
            'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
            'permanentLoanType' => 'Can circulate',
            'suppressFromDiscovery' => false },
          { 'id' => '99466f50-2b8c-51d4-8890-373190b8f6c4',
            'status' => 'Available',
            'barcode' => '12345679',
            'location' =>
            { 'effectiveLocation' => { 'code' => 'SAL3-STACKS' },
            'permanentLocation' => { 'code' => 'SAL3-STACKS' },
            'temporaryLocation' => {} },
            'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
            'permanentLoanType' => 'Can circulate',
            'suppressFromDiscovery' => false }] }
    end
    
    it 'defaults to application' do
      get :new, params: scannable_params
      expect(response).to render_template(layout: 'application')
    end

    it 'uses the modal layout when the modal param is set' do
      get :new, params: scannable_params.merge(modal: true)
      expect(response).to render_template(layout: 'modal')
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentsController do
  let(:user) { CurrentUser.new(username: 'somesunetid', patron_key: '513a9054-5897-11ee-8c99-0242ac120002', shibboleth: true) }
  let(:mock_patron) { instance_double(Folio::Patron, key: user.user_object.patron_key, payments:) }
  let(:mock_client) { instance_double(FolioClient, ping: true, pay_fines: nil) }
  let(:mock_graphql_client_response) do
    [
      { 'id' => '1', 'actions' => [{ 'dateAction' => '2019-01-01' }, { 'dateAction' => '2019-01-02' }],
        'status' => { 'name' => 'Closed' } },
      { 'id' => '2', 'actions' => [{ 'dateAction' => '2019-01-15' }] },
      { 'id' => '3', 'actions' => [{ 'dateAction' => '2019-02-01' }, { 'dateAction' => '2019-02-03' }],
        'status' => { 'name' => 'Closed' } }
    ]
  end
  let(:payments) { mock_graphql_client_response.map { |record| Folio::Account.new(record) } }

  before do
    allow(FolioClient).to receive(:new).and_return(mock_client)
    allow(controller).to receive_messages(patron_or_group: mock_patron)
    warden.set_user(user)
  end

  describe '#index' do
    context 'when a user has multiple payments' do
      before do
        get(:index)
      end

      it 'shows a list of payments from the payments array' do
        expect(assigns(:payments)).to all(be_a Folio::Account)
      end

      it 'shows the correct number of payments in the list' do
        expect(assigns(:payments).length).to eq 3
      end

      it 'shows the payments sorted appropriately (bills w/o a payment date at the top the reverse date sort)' do
        expect(assigns(:payments).map(&:key)).to eq(%w[2 3 1])
      end
    end

    context 'when a user has only one payment' do
      let(:mock_graphql_client_response) do
        [{ 'id' => '1', 'actions' => [{ 'dateAction' => '2019-01-15' }] }]
      end

      it 'wraps a single payment in an array' do
        get(:index)
        expect(assigns(:payments).first.key).to eq '1'
      end
    end
  end

  describe '#create' do
    before do
      post :create,
           params: { user_id: '513a9054-5897-11ee-8c99-0242ac120002', amount: '10.00', fine_ids: %w[1 2 3] }
    end

    it 'renders a form to send to cybersource' do
      expect(response).to render_template('cybersource_form')
    end
  end

  describe '#accept' do
    let(:cybersource_response) do
      instance_double(Cybersource::PaymentResponse, user_id: '513a9054-5897-11ee-8c99-0242ac120002',
                                                    amount: '10.00',
                                                    valid?: true,
                                                    payment_success?: true)
    end

    before do
      allow(controller).to receive(:cybersource_response).and_return(cybersource_response)
    end

    it 'updates the payment in the ILS' do
      post :accept
      expect(mock_client).to have_received(:pay_fines)
        .with(user_id: '513a9054-5897-11ee-8c99-0242ac120002', amount: '10.00')
    end

    it 'redirects to fines page' do
      post :accept
      expect(controller).to redirect_to(fines_path)
    end

    it 'flashes a success message' do
      post :accept
      expect(flash[:success]).to include('Success!').and include('$10.00 paid.')
    end

    context 'when the params sent back from cybersource do not pass validation' do
      before do
        allow(controller).to receive(:cybersource_response).and_raise(Cybersource::Security::InvalidSignature)
      end

      it 'flashes an error message' do
        post :accept
        expect(flash[:error]).to include('Payment failed.')
      end
    end

    context 'when cybersource rejected the payment' do
      before do
        allow(controller).to receive(:cybersource_response).and_raise(Cybersource::PaymentResponse::PaymentFailed)
      end

      it 'flashes an error message' do
        post :accept
        expect(flash[:error]).to include('Payment failed.')
      end
    end
  end

  describe '#cancel' do
    before { post :cancel }

    it 'redirects to the fines page' do
      expect(controller).to redirect_to(fines_path)
    end

    it 'flashes a cancellation message' do
      expect(flash[:error]).to include 'Payment canceled.'
    end
  end
end

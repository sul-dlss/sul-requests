# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cybersource::PaymentRequest do
  subject(:request_params) do
    described_class.new(user_id: '0340214b-5492-472d-b634-c5c115639465', amount: '1000.00', fine_ids:).sign!.to_h
  end

  let(:fine_ids) do
    %w[4085f2b8-80f4-431d-ac3c-25cc2b62d4f6
       a4aedaea-1750-461e-b7bd-2c90ba6b95bc
       a27c153e-b339-4fcb-8abb-fe846e37ded5
       ab6dc99f-bb59-44d0-93e8-efe36f99c6e5
       5eff6d10-9626-49e7-8f3f-78f833d77754
       af1ae4da-62df-43e7-9d97-c765911f2fb6
       7a850f26-8587-48d8-bb3c-bc7ea59c964f
       651d04fc-1cfd-4178-8f68-432ed994b935
       ede51d94-4db3-487e-9915-36c28d62423a
       8795b01c-878f-4bf5-93e0-ab6c2d7aefbe
       b7950294-ef0d-4478-b8e5-9fa9511d3f98
       8b3724de-498f-4517-b9cf-46e10863f42c
       fb9f3582-cbfd-4084-8d0b-7b8fe519886f]
  end

  before do
    allow(Cybersource::Security).to receive(:secret_key).and_return('very_secret')
  end

  it 'stores the amount of total charges' do
    expect(request_params[:amount]).to eq('1000.00')
  end

  it 'stores the user id as the transaction reference number' do
    expect(request_params[:reference_number]).to eq('0340214b-5492-472d-b634-c5c115639465')
  end

  it 'signs the transaction parameters' do
    expect(request_params[:signature]).to be_present
  end

  it 'includes compressed account ids in the merchant defined data 1 field' do
    expect(request_params[:merchant_defined_data1]).to eq('4085f2b:a4aedae:a27c153:ab6dc99:' \
                                                          '5eff6d1:af1ae4d:7a850f2:651d04f:' \
                                                          'ede51d9:8795b01:b795029:8b3724d')
  end

  it 'includes compressed account ids in the merchant defined data 2 field' do
    expect(request_params[:merchant_defined_data2]).to eq('fb9f358')
  end

  it 'includes nothing in the merchant defined data 3 field' do
    expect(request_params[:merchant_defined_data3]).to be_nil
  end

  it 'includes nothing in the merchant defined data 4 field' do
    expect(request_params[:merchant_defined_data4]).to be_nil
  end

  it 'includes nothing in the merchant defined data 5 field' do
    expect(request_params[:merchant_defined_data5]).to be_nil
  end
end

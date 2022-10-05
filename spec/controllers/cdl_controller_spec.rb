# frozen_string_literal: true

require 'rails_helper'

describe CdlController do
  describe '#availability' do
    it 'is accessible by anyone' do
      get :availability, params: { barcode: 'abc123' }
      expect(response).to be_successful
    end
  end

  describe '#checkin' do
    context 'public access' do
      it 'is restricted' do
        get :checkin, params: { hold_record_key: 'abc123' }
        expect(response).to redirect_to(
          '/sso/login?referrer=http%3A%2F%2Ftest.host%2Fcdl%2Fcheckin%3Fhold_record_key%3Dabc123'
        )
      end
    end

    context 'sso user' do
      before do
        allow(controller).to receive_messages(current_user: user)
        allow(user).to receive_messages(patron: Patron.new(patron_record))
      end

      let(:user) { create(:sso_user) }
      let(:patron_record) do
        {
          'fields' => {
            'holdRecordList' => [
              {
                'key' => 'abc123',
                'fields' => {
                  'comment' => 'CDL;'
                }
              }
            ]
          }
        }
      end

      it 'redirects when successful' do
        expect(CdlCheckout).to receive(:checkin).and_return({})
        get :checkin, params: { hold_record_key: 'abc123', return_to: 'http://example.com' }
        expect(response).to redirect_to(
          'http://example.com?success=true'
        )
      end
    end
  end

  describe '#checkout' do
    context 'public access' do
      it 'is restricted' do
        get :checkout, params: { id: 'ab123cd4567', barcode: '123456' }
        expect(response).to redirect_to(
          '/sso/login?referrer=http%3A%2F%2Ftest.host%2Fcdl%2Fcheckout%3Fbarcode%3D123456%26id%3Dab123cd4567'
        )
      end
    end

    context 'sso user' do
      before do
        allow(controller).to receive_messages(current_user: user)
        allow(user).to receive_messages(patron: Patron.new(patron_record))
      end

      let(:user) { create(:sso_user) }
      let(:patron_record) do
        {
          'fields' => {
            'holdRecordList' => [
              {
                'key' => 'abc123',
                'fields' => {
                  'comment' => 'CDL;'
                }
              }
            ]
          }
        }
      end

      it 'if no token exists render success' do
        expect(CdlCheckout).to receive(:checkout).and_return({})
        get :checkout, params: { id: 'ab123cd4567', barcode: '123456' }
        expect(response).to be_successful
      end

      it 'when things workout, redirect with token' do
        expect(CdlCheckout).to receive(:checkout).and_return({ token: 'token' })
        get :checkout, params: { id: 'ab123cd4567', barcode: '123456', return_to: 'http://example.com' }
        expect(response).to redirect_to(
          'http://example.com?token=eyJhbGciOiJIUzI1NiJ9.InRva2VuIg.aYiyhjXiai3MdvkQtp_vygZw6CR_ys0OzhdYVPbegsg'
        )
      end
    end
  end
end

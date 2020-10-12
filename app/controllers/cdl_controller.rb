# frozen_string_literal: true

# Controller to handle mediations for admins
class CdlController < ApplicationController
  authorize_resource class: false

  include ModalLayout

  rescue_from Exceptions::CdlCheckoutError, with: :handle_cdl_error
  rescue_from Exceptions::SymphonyError, with: :handle_symphony_error

  before_action :set_origin_header, only: [:availability]

  def set_origin_header
    response.headers['Access-Control-Allow-Origin'] = '*'
  end

  def availability
    availability_info = CdlAvailability.available(barcode: availability_params)
    render json: availability_info.to_json
  end

  def checkin
    hold_record_key = if checkin_params['token']
                        payload, _headers = decode_token(checkin_params['token'])

                        payload['hold_record_id']
                      elsif checkin_params['hold_record_key']
                        checkin_params['hold_record_key']
                      end

    CdlCheckout.checkin(hold_record_key, current_user)

    redirect_to checkin_params['return_to'] + '?success=true'
  end

  def checkout
    checkout = CdlCheckout.checkout(checkout_params['barcode'], checkout_params['id'], current_user)

    if checkout[:token]
      redirect_to checkout_params['return_to'] + '?token=' + encode_token(checkout[:token])

      return
    end

    @hold_record = checkout[:hold]

    render
  end

  def renew
    payload, _headers = decode_token(renew_params['token'])
    renewal = CdlCheckout.renew(payload['barcode'], payload['aud'], current_user)

    redirect_to renew_params['return_to'] + '?token=' + encode_token(renewal)
  end

  private

  def encode_token(payload)
    JWT.encode(payload, Settings.cdl.jwt.secret, Settings.cdl.jwt.algorithm)
  end

  def decode_token(token)
    JWT.decode(token, Settings.cdl.jwt.secret, true, { algorithm: Settings.cdl.jwt.algorithm })
  end

  def handle_cdl_error(exception)
    respond_to do |format|
      format.json { render json: { error: exception.message }.to_json, status: :bad_request }
      format.html { render 'cdl_error' }
    end
  end

  def handle_symphony_error(exception)
    respond_to do |format|
      format.json { render json: { error: exception.message }.to_json, status: :internal_server_error }
      format.html { render 'symphony_error' }
    end
  end

  def rescue_can_can(*)
    return super if webauth_user?

    redirect_to login_path(referrer: request.original_url)
  end

  def availability_params
    params.require(:barcode)
  end

  def checkout_params
    params.require(:id)
    params.require(:barcode)
    params.permit(:id, :barcode, :return_to)
  end

  def checkin_params
    params.permit(:token, :return_to, :hold_record_key)
  end

  def renew_params
    params.permit(:token, :return_to)
  end
end

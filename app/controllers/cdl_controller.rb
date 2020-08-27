# frozen_string_literal: true

# Controller to handle mediations for admins
class CdlController < ApplicationController
  authorize_resource class: false

  def availability
    availability_info = CdlAvailability.available(barcode: availability_params)
    render json: availability_info.to_json
  end

  def checkin
    # Decode jwt
    payload, _headers = JWT.decode(checkin_params['token'], Settings.cdl.jwt.secret, true, { algorithm: Settings.cdl.jwt.algorithm })
    circ_record = CircRecord.find(payload['jti'])

    render status: 400, json: 'The item is not checked out' and return if circ_record.item_barcode != payload['barcode']

    checkin = symphony_client.check_in_item(payload['barcode'])
    redirect_to checkin_params['return_to'] + '?success=true'
  end

  def checkout
    token = CdlCheckout.checkout(checkout_params['barcode'], checkout_params['id'], current_user)
    redirect_to checkout_params['return_to'] + '?token=' + token
  rescue Exceptions::CdlCheckoutError => e
    render json: { error: e.message }.to_json, status: :internal_server_error
  end

  private

  def symphony_client
    @symphony_client ||= SymphonyClient.new
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
    params.require(:token)
    params.permit(:token, :return_to)
  end
end

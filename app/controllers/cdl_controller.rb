# frozen_string_literal: true

# Controller to handle mediations for admins
class CdlController < ApplicationController
  authorize_resource class: false

  def availability
    availability_info = CdlAvailability.available(barcode: availability_params)
    render json: availability_info.to_json
  end

  def checkin
    circ_record = CircRecord.new()
    hold_record_id = nil

    if checkin_params['token']
      payload, _headers = JWT.decode(checkin_params['token'], Settings.cdl.jwt.secret, true, { algorithm: Settings.cdl.jwt.algorithm })
      hold_record_id = payload['hold_record_id']
      circ_record = CircRecord.find(payload['jti'])
      render status: :bad_request, json: { error: 'The item is not checked out' } and return if circ_record.item_barcode != payload['barcode']
    end

    if checkin_params['hold_record_key']
      hold_record = current_user.patron.holds.find { |hold| hold.key == checkin_params['hold_record_key'] }
      hold_record_id = hold_record.key
      render status: :bad_request, json: { error: 'The item is not checked out' } and return unless hold_record.circ_record&.exists?

      circ_record = hold_record.circ_record
    end

    render status: :bad_request, json: { error: 'The item is not active' } and return unless circ_record.exists?

    ## Check the item back in and cancel the hold
    symphony_client.check_in_item(circ_record.item_barcode)
    symphony_client.cancel_hold(hold_record_id)
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
    params.permit(:token, :return_to, :hold_record_key)
  end
end

# frozen_string_literal: true

# Controller to handle mediations for admins
class CdlController < ApplicationController
  authorize_resource class: false

  def checkin
    # Decode jwt
    payload, _headers = JWT.decode(checkin_params['token'], Settings.cdl.jwt.secret, true, { algorithm: Settings.cdl.jwt.algorithm })
    checkin = symphony_client.check_in_item(payload['barcode'])
    redirect_to checkin_params['return_to'] + '?success=true'
  end

  def checkout
    # look up callkey
    # place a hold on the material for the patron
    # make sure we can check the item out
    # check the item out to the pseudo patron
    # return jwt?
    # redirect_to referrer? with jwt
    # schedule a job to check the item back in?
    # schedule a job to remove the users hold on the item
    # correct checkout, at correct time, w/ correct user

    catalog_info = symphony_client.catalog_info(params['barcode'])
    barcode = catalog_info&.dig('fields', 'call', 'fields', 'itemList').select { |item| item.dig('fields','currentLocation','key') }.first&.dig('fields','barcode')
    callkey = catalog_info&.dig('fields', 'call', 'key')

    symphony_client.place_hold(
      comment: "CDL checkout for #{checkout_params['id']}",
      fill_by_date: DateTime.now + 1.year,
      patron_barcode: current_user.library_id,
      item: {
        call: {key: callkey, resource: '/catalog/call' },
        holdType: 'TITLE'
      }
      # key: 'CDL'
    )
    checkout = symphony_client.check_out_item(barcode, current_user.library_id)

    due_date = checkout&.dig('circRecord', 'fields', 'dueDate')
    messages = Array.wrap(checkout&.dig('messageList')).map { |message| message.dig('message') }

    if messages.present?
      render json: { error: messages.join(' ') }.to_json, status: :internal_server_error
      return
    end

    payload = {
      barcode: barcode,
      id: checkout_params['id'],
      sub: current_user.webauth,
      exp: DateTime.parse(due_date).to_i
    }
    token = JWT.encode(payload, Settings.cdl.jwt.secret, Settings.cdl.jwt.algorithm)
    redirect_to checkout_params['return_to'] + '?token=' + token
  end

  private

  def symphony_client
    @symphony_client ||= SymphonyClient.new
  end

  def rescue_can_can(*)
    return super if webauth_user?

    redirect_to login_path(referrer: request.original_url)
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

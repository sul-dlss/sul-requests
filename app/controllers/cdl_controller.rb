# frozen_string_literal: true

# Controller to handle mediations for admins
class CdlController < ApplicationController
  authorize_resource class: false

  def checkin
    # Decode jwt
    payload, _headers = JWT.decode(checkin_params['token'], nil, false)
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
    symphony_client.place_hold(
      comment: "CDL checkout for #{checkout_params['id']}",
      fill_by_date: DateTime.now + 1.year,
      patron_barcode: current_user.library_id,
      item: {
        itemBarcode: checkout_params['barcode'],
        holdType: 'TITLE'
      }
      # key: 'CDL'
    )
    checkout = symphony_client.check_out_item(checkout_params['barcode'], current_user.library_id)
    due_date = DateTime.parse(checkout&.dig('circRecord', 'fields', 'dueDate'))
    payload = {
      barcode: checkout_params['barcode'],
      id: checkout_params['id'],
      sub: current_user.webauth,
      exp: due_date.to_i
    }
    token = JWT.encode(payload, nil, 'none')
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

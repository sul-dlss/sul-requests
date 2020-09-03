# frozen_string_literal: true

# Procedurual service for "circulating" CDL content from symphony
class CdlCheckout
  attr_reader :druid, :user

  # @param barcode [String] item barcode
  # @param druid [String]
  # @param user [User]
  # @return [Hash] token payload
  def self.checkout(barcode, druid, user)
    new(druid, user).process_checkout(barcode)
  end

  # @param hold_record_key [String] Symphony hold record key
  # @param user [User] user
  # @return [Boolean]
  def self.checkin(hold_record_key, user)
    new(nil, user).process_checkin(hold_record_key)
  end

  # @param barcode [String] item barcode
  # @param druid [String]
  # @param user [User]
  # @return [Hash] token payload
  def self.renew(barcode, druid, user)
    new(druid, user).process_renewal(barcode)
  end

  def initialize(druid, user)
    @druid = druid
    @user = user
  end

  ##
  # Checkout does three things:
  #  - finds or creates a TITLE level hold on the call record for the patron
  #  - checks out an item to a CDL pseudopatron (NOTE: we select an eligible item
  #      from the call list, so it may be different than the barcode that came in)
  #  - updates the hold comment to link the hold to the actual checkout
  #
  # @param barcode [String] item barcode
  # @return [Hash] token payload
  def process_checkout(barcode)
    item_info = CatalogInfo.find(barcode)

    hold = find_hold(item_info.callkey) || place_hold(item_info.callkey)

    if hold.next_up_cdl?
      circ_record = hold.circ_record
      symphony_client.edit_circ_record_info(circ_record.key, dueDate: item_info.loan_period.from_now.iso8601)
    else
      return { token: create_token(hold.circ_record, hold.key), hold: hold } if hold.circ_record&.exists?

      selected_item = item_info.items.find { |item| item.current_location != 'CHECKEDOUT' }

      return { token: nil, hold: hold } unless selected_item

      checkout = place_checkout(selected_item.barcode, dueDate: item_info.loan_period.from_now.iso8601)
      circ_record = CircRecord.new(checkout&.dig('circRecord'))
    end

    comment = "CDL;#{druid};#{circ_record.key};#{circ_record.checkout_date.to_i}"
    update_hold_response = symphony_client.update_hold(hold.key, comment: comment)
    check_for_symphony_errors(update_hold_response)

    { token: create_token(circ_record, hold.key), hold: hold }
  end

  def process_renewal(barcode)
    item_info = CatalogInfo.find(barcode)
    hold = find_hold(item_info.callkey)

    raise(Exceptions::CdlCheckoutError, 'Could not find hold record') unless hold&.exists? && hold&.cdl?
    raise(Exceptions::CdlCheckoutError, 'Could not find circ record') unless hold&.circ_record&.exists?

    due_date = hold.circ_record.due_date

    # Our time for newewal is w/i 5 minuts, we're adding an addl. minute of slop here
    raise(Exceptions::CdlCheckoutError, 'Item not renewable') if due_date.before?(6.minutes.ago)

    renewal = place_renewal(hold.item_key, dueDate: item_info.loan_period.from_now.iso8601)

    circ_record = CircRecord.new(renewal&.dig('circRecord'))
    comment = "CDL;#{druid};#{circ_record.key};#{circ_record.checkout_date.to_i}"
    update_hold_response = symphony_client.update_hold(hold.key, comment: comment)
    check_for_symphony_errors(update_hold_response)

    create_token(circ_record, hold.key)
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  ##
  # CDL checkins do three things:
  #  - check in the item from the CDL pseudopatron
  #  - remove the CDL hold for the patron
  #  - (TODO:) add the token to the blocklist so it can't be used
  # @param [String] cdl hold record key
  # @return [Boolean]
  def process_checkin(hold_record_key)
    hold_record = user.patron.holds.find { |hold| hold.key == hold_record_key }

    raise(Exceptions::CdlCheckoutError, 'Could not find hold record') unless hold_record&.exists? && hold_record&.cdl?

    ## Check the item back in and cancel the hold
    if hold_record.circ_record&.exists?
      unless hold_record.circ_record.patron_barcode == Settings.cdl.pseudo_patron_id
        raise(Exceptions::CdlCheckoutError, 'Item not checked out for digital lending')
      end

      checkin_response = symphony_client.check_in_item(hold_record.circ_record.item_barcode)
      check_for_symphony_errors(checkin_response)
    end

    cancel_hold_response = symphony_client.cancel_hold(hold_record.key)
    check_for_symphony_errors(cancel_hold_response)

    true
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  private

  # Create a token payload that suspiciously resembles
  # a JWT payload.
  def create_token(circ_record, hold_record_id)
    {
      jti: "#{circ_record.key}-#{circ_record.checkout_date.to_i}",
      iat: Time.zone.now.to_i,
      barcode: circ_record.item_barcode,
      aud: druid,
      sub: user.webauth,
      exp: circ_record.due_date.to_i,
      hold_record_id: hold_record_id
    }
  end

  def find_hold(callkey)
    user.patron.holds.find do |hold_record|
      hold_record.item_call_key == callkey && hold_record.active?
    end
  end

  def place_hold(callkey)
    response = symphony_client.place_hold(
      comment: "CDL;#{druid}", # max 50
      fill_by_date: DateTime.now + 1.year,
      patron_barcode: user.library_id,
      item: {
        call: { key: callkey, resource: '/catalog/call' },
        holdType: 'TITLE'
      },
      key: 'SUL'
    )

    check_for_symphony_errors(response)

    HoldRecord.new(response&.dig('holdRecord') || {})
  end

  def place_checkout(selected_barcode, **additional_params)
    response = symphony_client.check_out_item(selected_barcode, Settings.cdl.pseudo_patron_id, **additional_params)

    check_for_symphony_errors(response)

    response
  end

  def place_renewal(selected_barcode, **additional_params)
    response = symphony_client.renew_item(selected_barcode, Settings.cdl.pseudo_patron_id, **additional_params)

    check_for_symphony_errors(response)

    response
  end

  def symphony_client
    @symphony_client ||= SymphonyClient.new
  end

  def check_for_symphony_errors(response)
    error_messages = Array.wrap(response&.dig('messageList')).map { |message| message.dig('message') }

    raise(Exceptions::SymphonyError, error_messages.join(' ')) if error_messages.present?
  end
end

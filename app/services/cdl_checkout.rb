# frozen_string_literal: true

# Procedurual service for checking out CDL content from symphony
class CdlCheckout
  attr_reader :barcode, :druid, :user

  def self.checkout(barcode, druid, user)
    new(barcode, druid, user).process_checkout
  end

  def self.checkin(hold_record_key, user)
    symphony_client = SymphonyClient.new

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
  end

  def initialize(barcode, druid, user)
    @barcode = barcode
    @druid = druid
    @user = user
  end

  ##
  # @return token [String]
  def process_checkout
    hold = find_hold || place_hold

    return create_token(hold.circ_record, hold.key) if hold.circ_record&.active?

    checkout = place_checkout
    check_for_symphony_errors(checkout)

    circ_record = CircRecord.new(checkout&.dig('circRecord'))
    update_hold_response = symphony_client.update_hold(hold.key, comment: "CDL;#{druid};#{circ_record.key};#{circ_record.due_date.iso8601}")
    check_for_symphony_errors(update_hold_response)

    create_token(circ_record, hold.key)
  end

  def create_token(circ_record, hold_record_id)
    {
      jti: circ_record.key,
      iat: Time.zone.now.to_i,
      barcode: circ_record.item_barcode,
      aud: druid,
      sub: user.webauth,
      exp: circ_record.due_date.to_i,
      hold_record_id: hold_record_id
    }
  end

  def find_hold
    user.patron.holds.find { |hold_record| hold_record.item_call_key == callkey }
  end

  def place_hold
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

  def place_checkout
    symphony_client.check_out_item(selected_barcode, Settings.cdl.pseudo_patron_id)
  end

  def symphony_client
    @symphony_client ||= SymphonyClient.new
  end

  private

  def callkey
    @callkey ||= catalog_info&.dig('fields', 'call', 'key')
  end

  def selected_barcode
    ## Eventually we may have to figure out "which" one to grab (maybe not the first)
    Array.wrap(catalog_info&.dig('fields', 'call', 'fields', 'itemList'))
         .select { |item| item.dig('fields','currentLocation','key') }
         .first&.dig('fields', 'barcode')
  end

  def catalog_info
    @catalog_info ||= symphony_client.catalog_info(barcode)
  end

  def check_for_symphony_errors(response)
    error_messages = Array.wrap(response&.dig('messageList')).map { |message| message.dig('message') }

    raise(Exceptions::SymphonyError, error_messages.join(' ')) if error_messages.present?
  end
end

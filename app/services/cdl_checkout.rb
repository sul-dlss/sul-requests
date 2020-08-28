# frozen_string_literal: true

# Procedurual service for checking out CDL content from symphony
class CdlCheckout
  attr_reader :barcode, :druid, :user

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

    error_messages = Array.wrap(checkout&.dig('messageList')).map { |message| message.dig('message') }

    raise(Exceptions::CdlCheckoutError, error_messages.join(' ')) if error_messages.present?

    circ_record = CircRecord.new(checkout&.dig('circRecord'))
    symphony_client.update_hold(hold.key, comment: "CDL;#{druid};#{circ_record.key};#{circ_record.due_date.iso8601}")

    create_token(circ_record, hold.key)
  end

  def create_token(circ_record, hold_record_id)
    payload = {
      jti: circ_record.key,
      barcode: circ_record.item_barcode,
      aud: druid,
      sub: user.webauth,
      exp: circ_record.due_date.to_i,
      hold_record_id: hold_record_id
    }
    JWT.encode(payload, Settings.cdl.jwt.secret, Settings.cdl.jwt.algorithm)
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

    HoldRecord.new(response&.dig('holdRecord') || {})
  end

  def place_checkout
    symphony_client.check_out_item(selected_barcode, Settings.cdl.pseudo_patron_id)
  end

  def self.checkout(barcode, druid, user)
    new(barcode, druid, user).process_checkout
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
end

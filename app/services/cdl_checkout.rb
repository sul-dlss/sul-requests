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
    hold = find_hold

    if hold.present?
      comment = hold.dig('fields', 'comment').to_s
      cdl, _druid, circ_record_key = comment.split(';', 3)
      if cdl == 'CDL' && circ_record_key.present?
        circ_record = CircRecord.find(circ_record_key)
        return create_token(circ_record) if circ_record.active?
      end
    else
      hold = place_hold
    end
    checkout = place_checkout

    error_messages = Array.wrap(checkout&.dig('messageList')).map { |message| message.dig('message') }

    raise(Exceptions::CdlCheckoutError, error_messages.join(' ')) if error_messages.present?

    # TODOS:
    # schedule a job to check the item back in?
    # schedule a job to remove the users hold on the item

    circ_record = CircRecord.new(checkout&.dig('circRecord'))
    update_hold = symphony_client.update_hold(hold['key'], comment: "CDL;#{druid};#{circ_record.key}")

    create_token(circ_record)
  end

  def create_token(circ_record)
    payload = {
      jti: circ_record.key,
      barcode: circ_record.item_barcode,
      aud: druid,
      sub: user.webauth,
      exp: circ_record.due_date.to_i
    }
    JWT.encode(payload, Settings.cdl.jwt.secret, Settings.cdl.jwt.algorithm)
  end

  def find_hold
    user.patron.holds.find { |hold_record| hold_record.dig('fields', 'item', 'fields', 'call', 'key') == callkey }
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

    response&.dig('holdRecord')
  end

  def place_checkout
    symphony_client.check_out_item(selected_barcode, 'CDL-CHECKEDOUT')
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

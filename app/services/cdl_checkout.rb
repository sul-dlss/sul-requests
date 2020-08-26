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
        circ_record = symphony_client.circ_record_info(circ_record_key)
        if circ_record.present? && circ_record&.dig('fields', 'status') == 'ACTIVE'
          barcode = circRecord.dig('fields', 'item', 'fields', 'barcode')
          return create_token(circRecord.dig('fields', 'dueDate'), barcode)
        end
      end
    else
      hold = place_hold
    end
    checkout = place_checkout

    due_date = checkout&.dig('circRecord', 'fields', 'dueDate')
    error_messages = Array.wrap(checkout&.dig('messageList')).map { |message| message.dig('message') }

    raise(Exceptions::CdlCheckoutError, error_messages.join(' ')) if error_messages.present?

    # TODOS:
    # schedule a job to check the item back in?
    # schedule a job to remove the users hold on the item

    update_hold = symphony_client.update_hold(hold['key'], comment: "CDL;#{druid};#{checkout&.dig('circRecord', 'key')}")

    create_token(due_date, selected_barcode)
  end

  def create_token(due_date, barcode)
    payload = {
      barcode: barcode,
      aud: druid,
      sub: user.webauth,
      exp: DateTime.parse(due_date).to_i
    }
    JWT.encode(payload, Settings.cdl.jwt.secret, Settings.cdl.jwt.algorithm)
  end

  def find_hold
    user.patron.holds.find { |hold_record| hold_record.dig('fields', 'call', 'key') == callkey }
  end

  def place_hold
    symphony_client.place_hold(
      comment: "CDL;#{druid}", # max 50
      fill_by_date: DateTime.now + 1.year,
      patron_barcode: user.library_id,
      item: {
        call: { key: callkey, resource: '/catalog/call' },
        holdType: 'TITLE'
      },
      key: 'SUL'
    )
  end

  def place_checkout
    symphony_client.check_out_item(selected_barcode, 'HOLD@GR')
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

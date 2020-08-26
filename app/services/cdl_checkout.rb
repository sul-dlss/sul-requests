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
    place_hold
    checkout = place_checkout

    due_date = checkout&.dig('circRecord', 'fields', 'dueDate')
    error_messages = Array.wrap(checkout&.dig('messageList')).map { |message| message.dig('message') }

    raise(Exceptions::CdlCheckoutError, error_messages.join(' ')) if error_messages.present?

    # TODOS:
    # schedule a job to check the item back in?
    # schedule a job to remove the users hold on the item
    create_token(due_date)
  end

  def create_token(due_date)
    payload = {
      barcode: selected_barcode,
      aud: druid,
      sub: user.webauth,
      exp: DateTime.parse(due_date).to_i
    }
    JWT.encode(payload, Settings.cdl.jwt.secret, Settings.cdl.jwt.algorithm)
  end

  def place_hold
    symphony_client.place_hold(
      comment: "CDL checkout for #{druid}",
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
    symphony_client.check_out_item(selected_barcode, user.library_id)
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

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
  rescue Exceptions::SymphonyError => e
    SubmitCdlCheckoutJob.perform_later(user, druid, barcode)
    raise e
  end

  # @param hold_record_key [String] Symphony hold record key
  # @param user [User] user
  # @return [Boolean]
  def self.checkin(hold_record_key, user)
    new(nil, user).process_checkin(hold_record_key)
  rescue Exceptions::SymphonyError
    SubmitCdlCheckinJob.perform_later(user, hold_record_key)
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

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
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
    item_info = CatalogInfo.find(barcode, return_holds: true)

    hold = find_hold(item_info) || place_hold(item_info)

    if hold.next_up_cdl?
      cdl_logger "Checking out #{barcode} for next-up patron #{user.patron.anonymized_id}"
      circ_record = hold.circ_record
      symphony_client.edit_circ_record_info(circ_record.key, dueDate: item_info.loan_period.from_now.iso8601)
    else
      return { token: create_token(hold.circ_record, hold.key), hold: hold } if hold.circ_record&.exists?

      selected_item = item_info.items.select(&:cdlable?).find { |item| item.current_location != 'CHECKEDOUT' }

      unless selected_item
        items = item_info.items.count(&:cdlable?)
        cdl_logger "Adding hold #{hold.key} for waitlisted patron #{user.patron.anonymized_id}"

        CdlWaitlistMailer.on_waitlist(hold.key, items: items).deliver_later
        return { token: nil, hold: hold, items: items }
      end

      cdl_logger "Checking out #{selected_item.barcode} for patron #{user.patron.anonymized_id}"
      checkout = place_checkout(selected_item.barcode, dueDate: item_info.loan_period.from_now.iso8601)
      circ_record = CircRecord.new(checkout&.dig('circRecord'))
    end

    comment = "CDL;#{druid};#{circ_record.key};#{circ_record.checkout_date.to_i};ACTIVE"
    retry_symphony_errors { symphony_client.update_hold(hold.key, comment: comment) }

    { token: create_token(circ_record, hold.key), hold: hold }
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  # rubocop:disable Metrics/CyclomaticComplexity
  def process_renewal(barcode)
    item_info = CatalogInfo.find(barcode, return_holds: true)
    hold = find_hold(item_info)

    raise(Exceptions::CdlCheckoutError, 'Could not find hold record') unless hold&.exists? && hold&.cdl?
    raise(Exceptions::CdlCheckoutError, 'Could not find circ record') unless hold&.circ_record&.exists?

    due_date = hold.circ_record.due_date

    # Our time for newewal is w/i 5 minuts, we're adding an addl. minute of slop here
    raise(Exceptions::CdlCheckoutError, 'Item not renewable') unless due_date.before?(6.minutes.from_now)

    cdl_logger "Renewing hold #{hold.key} for patron #{user.patron.anonymized_id}"
    renewal = place_renewal(hold.item_key, dueDate: item_info.loan_period.from_now.iso8601)

    circ_record = CircRecord.new(renewal&.dig('circRecord'))
    comment = "CDL;#{druid};#{circ_record.key};#{circ_record.checkout_date.to_i};ACTIVE"
    update_hold_response = symphony_client.update_hold(hold.key, comment: comment)
    retry_symphony_errors { update_hold_response }

    create_token(circ_record, hold.key)
  end
  # rubocop:enable Metrics/CyclomaticComplexity

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

    cdl_logger "Checking in #{hold_record_key} for patron #{user.patron.anonymized_id}"

    comment = hold_record.comment.gsub('ACTIVE', 'COMPLETED').gsub('WAITLIST', 'CANCELED').gsub('NEXT_UP', 'CANCELED')
    symphony_client.update_hold(hold_record.key, comment: comment)
    cancel_hold_response = symphony_client.cancel_hold(hold_record.key)

    if hold_record.circ_record&.exists?
      invalidate_jwt_token(hold_record.circ_record, hold_record_key)
      CdlWaitlistJob.perform_later(hold_record.circ_record.key, checkout_date: hold_record.circ_record.checkout_date)
    end

    check_for_symphony_errors(cancel_hold_response)

    true
  end

  private

  # Create a token payload that suspiciously resembles
  # a JWT payload.
  def create_token(circ_record, hold_record_id)
    {
      jti: "#{circ_record.key}-#{circ_record.checkout_date.to_i}-#{hold_record_id}",
      iat: Time.zone.now.to_i,
      barcode: circ_record.item_barcode,
      aud: druid,
      sub: user.sunetid,
      exp: circ_record.due_date.to_i,
      hold_record_id: hold_record_id
    }
  end

  def find_hold(item)
    return nil unless user.patron

    user.patron.holds.find do |hold_record|
      hold_record.item_call_key == item.callkey && hold_record.active?
    end
  end

  def place_hold(item)
    response = symphony_client.place_hold(
      comment: "CDL;#{druid};;;WAITLIST", # max 50
      fill_by_date: DateTime.now + 1.year,
      patron_barcode: user.library_id,
      item: {
        item: { key: item.cdl_proxy_hold_item.key, resource: '/catalog/item' },
        holdType: 'COPY'
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
    raise(Exceptions::SymphonyError, 'No response fom symphony') if response.nil?

    errors = Array.wrap(response&.dig('messageList'))

    raise(Exceptions::SymphonyError, errors) if errors.any?

    response
  end

  def retry_symphony_errors(times: 3)
    i = 0

    begin
      check_for_symphony_errors(yield)
    rescue Exceptions::SymphonyError => e
      raise e if i > times

      i += 1
      sleep 1
      retry
    end
  end

  def invalidate_jwt_token(circ_record, hold_record_id)
    return unless redis

    key = "#{circ_record.key}-#{circ_record.checkout_date.to_i}-#{hold_record_id}"

    redis.multi do
      redis.set("cdl.#{key}", 'expired')
      redis.expireat(key.to_s, circ_record.due_date.to_i)
    end
  rescue => e
    Honeybadger.notify(e) if Rails.env.production?
    Rails.logger.error(e)
  end

  def redis
    return unless Settings.cdl.redis || ENV['REDIS_URL']

    @redis ||= Redis.new(Settings.cdl.redis.to_h)
  end

  def cdl_logger(*args)
    Rails.logger.tagged('CDL') do
      Rails.logger.info(*args)
    end
  end
end

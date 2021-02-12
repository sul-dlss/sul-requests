# frozen_string_literal: true

##
# Rails Job to submit a CDL checkout request to Symphony for processing
class SubmitCdlCheckoutJob < ApplicationJob
  queue_as :default
  retry_on Exceptions::SymphonyError

  def perform(user, druid, barcode)
    response = CdlCheckout.new(druid, user).process_checkout(barcode)

    # the checkout request gave us a token, but our user is long-gone. Send them a next-up email
    # as if they were actually on the waitlist (they have no way to know they weren't, so :shrug:)
    CdlWaitlistMailer.youre_up(response[:hold].key, response[:hold].circ_record_key).deliver_later if response[:token]
  end
end

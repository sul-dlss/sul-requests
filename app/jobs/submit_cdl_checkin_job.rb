# frozen_string_literal: true

##
# Rails Job to submit a CDL checkin to Symphony for processing
class SubmitCdlCheckinJob < ApplicationJob
  queue_as :default
  retry_on Exceptions::SymphonyError

  def perform(user, hold_record_key)
    CdlCheckout.new(nil, user).process_checkin(hold_record_key)
  end
end

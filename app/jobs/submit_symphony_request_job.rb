# frozen_string_literal: true

##
# This transforms the enqueued job to a SubmitFolioRequestJob
class SubmitSymphonyRequestJob < ApplicationJob
  queue_as :default

  def perform(request_id, options = {})
    SubmitFolioRequestJob.perform_later(request_id, options)
  end
end

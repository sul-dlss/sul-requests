# frozen_string_literal: true

##
# Rails Job to submit a request to ILLiad for handling (and possible rerouting)
class SubmitPatronRequestJob < ApplicationJob
  queue_as :default

  def perform(patron_request) # rubocop:disable Metrics/AbcSize
    ilb_items, folio_items = patron_request.selected_items.partition do |item|
      patron_request.scan? ||
        (patron_request.patron.ilb_eligible? && patron_request.fulfillment_type == 'recall' && item.hold_recallable?(patron_request.patron))
    end

    illiad_response_data = ilb_items.each_with_object({}) do |item, responses|
      responses[item.id] = SubmitIlliadPatronRequestJob.perform_now(patron_request, item.id)
    end

    folio_responses = folio_items.each_with_object({}) do |item, responses|
      responses[item.id] = SubmitFolioPatronRequestJob.perform_now(patron_request, item.id)
    end

    patron_request.update(illiad_response_data:, folio_responses:)
  end
end

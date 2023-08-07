# frozen_string_literal: true

##
# Background job to send requests to IPLC.
# If Reshare has the item and we succesfully request it, let the user know it is on the way.
# If Reshare does not have it or we cannot succesfully request it, trigger the normal request workflow.
class SubmitIplcListenerJob < ApplicationJob
  discard_on ActiveRecord::RecordNotFound do |job, _error|
    Honeybadger.notify(
      "Attempted to call Reshare for Request with ID #{job.request_id}, but no such Request was found."
    )
  end

  def perform(request_id, instance_uuid, instance_title)
    request = Request.find(request_id)

    logger.info("Started SubmitIplcRequestJob for request #{request_id}")

    begin
      make_iplc_request(request, instance_uuid, instance_title)
    rescue StandardError => e
      Honeybadger.notify("IPLC Request failed for #{request_id} with #{e}. Submitted to the ILS instead.")

      request.send_to_ils_now!
    end

    logger.info("Completed SubmitIplcRequestJob for request #{request_id}")
  end

  def make_iplc_request(request, instance_uuid, instance_title)
    iplc_response = IplcWrapper.new(request, instance_uuid, instance_title)

    raise 'IPLC HTTP request failed' unless iplc_response.success?

    request.borrow_direct_response_data = iplc_response.as_json
    request.via_borrow_direct = true
    # We don't care if this save was successful or not, because if it went through the back-end service,
    # then requests is no longer the source of truth for this.
    request.save

    request.send_approval_status!
  end

  # Basic client for working with the IPLC listener HTTP API.
  class IplcWrapper
    attr_reader :request, :instance_uuid, :instance_title

    def initialize(request, instance_uuid, instance_title)
      @request = request
      @instance_uuid = instance_uuid
      @instance_title = instance_title
    end

    def as_json(_options = nil)
      {
        response:,
        params: iplc_params
      }
    end

    def success?
      iplc_request.status.success?
    end

    private

    def iplc_request
      @iplc_request ||= HTTP.get(Settings.borrow_direct.iplc_listener_url, params: iplc_params)
    end

    def response
      @response ||= JSON.parse(iplc_request.body.to_s)
    end

    def iplc_params
      {
        svc_id: 'json',
        req_id: iplc_patron_id,
        rft_id: instance_uuid,
        'rft.title': instance_title,
        'res.org': 'ISIL:US-CST',
        'svc.pickupLocation': iplc_pickup_location_code,
        rfr_id: request.to_global_id.to_s
      }
    end

    def iplc_patron_id
      request.user.university_id
    end

    # Symphony location codes can be converted to ReShare location codes by:
    # 1) Adding the prefix STA_
    # 2) Replacing - with _
    #
    # Examples:
    # Symphony code => ReShare code
    # LAW           => STA_LAW
    # EAST-ASIA     => STA_EAST_ASIA
    def iplc_pickup_location_code
      Settings.libraries[request.destination]&.iplc_pickup_location_code || "STA_#{request.destination.tr('-', '_')}"
    end
  end
end

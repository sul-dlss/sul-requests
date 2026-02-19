# frozen_string_literal: true

###
#  Controller for displaying Aeon requests for a user
###
class AeonRequestsController < ApplicationController
  def drafts
    authorize! :read, Aeon::Request

    @aeon_requests = current_user&.aeon&.draft_requests || []
  end

  def cancelled
    authorize! :read, Aeon::Request

    @aeon_requests = current_user&.aeon&.cancelled_requests || []
  end

  def submitted
    authorize! :read, Aeon::Request

    @aeon_requests = current_user&.aeon&.submitted_requests || []
  end

  def resubmit
    authorize! :update, aeon_request

    AeonClient.new.update_request_route(transaction_number: params[:id], status: 'Submitted by User')
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("request-#{params[:id]}") }
    end
  end

  def destroy
    authorize! :destroy, aeon_request

    AeonClient.new.update_request_route(transaction_number: params[:id], status: 'Cancelled by User')
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("request-#{params[:id]}") }
    end
  end

  private

  def aeon_request
    current_user.aeon.requests.find { |request| request.transaction_number == params[:id].to_i }
  end
end

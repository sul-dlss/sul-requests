# frozen_string_literal: true

###
#  Controller for displaying Aeon requests for a user
###
class AeonRequestsController < ApplicationController
  def drafts
    authorize! :read, Aeon::Request

    @aeon_requests = current_user&.aeon&.draft_requests || []
  end

  def submitted
    authorize! :read, Aeon::Request

    @aeon_requests = current_user&.aeon&.submitted_requests || []
  end

  def destroy
    AeonClient.new.delete_request(transaction_number: params[:id])
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(params[:id]) }
    end
  end
end

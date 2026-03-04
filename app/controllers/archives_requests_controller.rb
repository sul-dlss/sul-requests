# frozen_string_literal: true

##
# Controller for handling archives requests with EAD XML data
class ArchivesRequestsController < ApplicationController
  include AeonController

  def show
    @patron_request = current_user.patron_requests.find(params[:id])
    @aeon_requests = Aeon::RequestGrouping.new(current_user.aeon.requests.select do |x|
      x.reference_number == @patron_request.to_global_id.to_s
    end)
  end

  private

  def authorize_new_request
    return render 'login' unless current_user.email_address

    authorize! :new, Aeon::Request
  end
end

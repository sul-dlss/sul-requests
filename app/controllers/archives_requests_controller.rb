# frozen_string_literal: true

##
# Controller for handling archives requests with EAD XML data
class ArchivesRequestsController < ApplicationController
  rescue_from EadClient::Error, with: :handle_ead_client_error

  def show
    @ead = EadClient.fetch(ead_url_param)
  end

  def ead_url_param
    # Handle both 'value' and 'Value' params for compatibility (Aeon currently accepts Value)

    return params.require(:Value) if params[:Value].present?

    params.require(:value)
  end

  def handle_ead_client_error
    render 'error'
  end
end

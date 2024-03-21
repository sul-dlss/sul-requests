# frozen_string_literal: true

# Controller for reseting a Barcode+PIN user's PIN
class ResetPinsController < ApplicationController
  before_action :logout_user!
  rescue_from ActiveSupport::MessageEncryptor::InvalidMessage, with: :invalid_token
  rescue_from FolioClient::IlsError, with: :request_failed

  # Renders the first step for resetting the PIN
  #
  # GET /reset_pin
  def index; end

  # Trigger a reset request for the PIN; this will send the patron an email
  # (using their email address on file) with a link back to our change form and
  # a token for completing the reset
  #
  # Ignore errors indicating the patron wasn't found in the ILS; we don't want
  # to leak information about presence/validity of library IDs
  #
  # POST /reset_pin
  def reset
    suppress ActiveRecord::RecordNotFound do
      patron = ils_client.find_patron_by_barcode(library_id_param, patron_info: false)

      ResetPinsMailer.with(patron:).reset_pin.deliver_now
    end

    flash[:success] = t 'reset_pin.success_html', library_id: params['library_id']
    redirect_to login_path
  end

  # Renders the third step for resetting a PIN, where we prompt the user
  # to enter a new pin
  #
  # GET /change_pin/:token
  def change_form; end

  # Finally, trigger the PIN update in the ILS using the token the user
  # received in their email and the new PIN they just entered
  #
  # POST /change_pin
  def change
    ils_client.change_pin(*change_pin_with_token_params)
    flash[:success] = t 'change_pin.success_html'
    redirect_to login_path
  end

  private

  def logout_user!
    redirect_to logout_path
  end

  def ils_client
    @ils_client ||= FolioClient.new
  end

  def library_id_param
    params.require(:library_id)
  end

  def change_pin_with_token_params
    params.require([:token, :pin])
  end

  def invalid_token
    flash[:error] = t 'change_pin.invalid_token_html'
    redirect_to reset_pin_path
  end

  def request_failed
    flash[:error] = t 'reset_pin.request_failed_html'
    redirect_to reset_pin_path
  end
end

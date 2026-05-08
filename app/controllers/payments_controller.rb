# frozen_string_literal: true

# Controller for handling payment of fines.
class PaymentsController < ApplicationController
  include FolioController

  before_action :authenticate_user!

  # Cybersource is POSTing back to our controller, so we don't
  # get an authenticity token that the cross-site request
  # forgery protection can use to validate the request
  skip_forgery_protection only: [:accept, :cancel]

  rescue_from Cybersource::Security::InvalidSignature,
              Cybersource::PaymentResponse::PaymentFailed, with: :payment_failed
  rescue_from FolioClient::Error, with: :ils_request_failed

  # Render the payment history page
  #
  # GET /payments
  # GET /payments.json
  def index
    @payments = patron_or_group.payments.sort_by { |payment| payment.sort_key(:payment_date) }

    respond_to do |format|
      format.html { render }
      format.json { render json: payments_json_response }
    end
  end

  # Send the user to Cybersource to make a payment via an interstitial form
  #
  # POST /payments
  def create
    @params = cybersource_request

    render 'cybersource_form', layout: false
  end

  # The payment was accepted by Cybersource, so update the fines in the ILS
  #
  # POST /payments/accept
  def accept
    FolioClient.new.pay_fines(user_id: cybersource_response.user_id,
                              amount: cybersource_response.amount)

    redirect_to fines_path, flash: {
      success: (t 'mylibrary.fine_payment.accept_html', amount: cybersource_response.amount)
    }
  end

  # The user canceled the payment in Cybersource
  #
  # POST /payments/cancel
  def cancel
    redirect_to fines_path, flash: { error: (t 'mylibrary.fine_payment.cancel_html') }
  end

  private

  # Formatted for use by the ajax_in_place_update library
  def payments_json_response
    {
      key: 'payments',
      type: 'async',
      html: render_to_string(formats: [:html], layout: false)
    }
  end

  def create_payment_params
    params.permit([:user_id, :amount, { fine_ids: [] }])
  end

  def cybersource_request
    Cybersource::PaymentRequest.new(**create_payment_params.to_h.symbolize_keys).sign!
  end

  def cybersource_response
    Cybersource::PaymentResponse.new(params.permit(:singled_field_names, :unsigned_field_names, :decision, :signature,
                                                   :req_reference_number, :req_amount, :req_merchant_defined_data1,
                                                   :req_merchant_defined_data2, :req_merchant_defined_data3,
                                                   :req_merchant_defined_data4).to_h).validate!
  end

  def payment_failed
    redirect_to fines_path, flash: { error: (t 'mylibrary.fine_payment.payment_failed_html') }
  end

  def ils_request_failed
    redirect_to fines_path, flash: { error: (t 'mylibrary.fine_payment.request_failed_html') }
  end
end

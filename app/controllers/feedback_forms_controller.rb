# frozen_string_literal: true

###
#  Controller to handle feedback from app
###
class FeedbackFormsController < ApplicationController
  def new; end

  def create
    FeedbackMailer.submit_feedback(params, request.remote_ip).deliver_now if valid?

    respond_to do |format|
      format.json { render json: feedback_flash_messages }
      format.html { redirect_to params[:url], flash: feedback_flash_messages }
    end
  end

  protected

  def url_regex
    %r/.*href=.*|.*url=.*|.*https?:\/{2}.*/i
  end

  # rubocop:disable Metrics/AbcSize
  def errors
    errors = []
    errors << 'You must pass the reCAPTCHA challenge' if !current_user? && !verify_recaptcha
    errors << 'A message is required' if params[:message].blank?
    if params[:email_address].present?
      errors << 'You have filled in a field that makes you appear as a spammer.' \
                'Please follow the directions for the individual form fields.'
    end
    if params[:user_agent].to_s =~ url_regex || params[:viewport].to_s =~ url_regex
      errors << 'Your message appears to be spam, and has not been sent.'
    end
    errors
  end

  # rubocop:enable Metrics/AbcSize
  def valid?
    errors.empty?
  end

  def feedback_flash_messages
    feedback_messages = {}
    if valid?
      feedback_messages[:success] = t 'sul_requests.feedback_form.success'
    else
      feedback_messages[:warning] = errors.join('<br/>')
    end
    feedback_messages
  end
end

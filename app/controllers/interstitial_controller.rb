# frozen_string_literal: true

###
#  This controller simply handles incoming requests (and responds immediately)
#  then redirects the user to the requested url. This allows us to take the user from authentication
#  and send them to their destination w/o allowing them to submit multiple superfluous requests
###
class InterstitialController < ApplicationController
  layout false

  before_action do
    raise ActionController::Redirecting::UnsafeRedirectError unless redirect_param_same_as_host?
  end

  def show
    @redirect_to = CGI.unescape(params[:redirect_to])
  end

  private

  def redirect_param_same_as_host?
    return false if params[:redirect_to].blank?

    param_host = begin
      URI.parse(CGI.unescape(params[:redirect_to]))
    rescue URI::InvalidURIError
      URI.parse(params[:redirect_to])
    end

    param_host.host == request.host
  end
end

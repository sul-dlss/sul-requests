###
#  This controller simply handles incoming requests (and responds immediately)
#  then redirects the user to the requested url. This allows us to take the user from WebAuth
#  and send them to their destination w/o allowing them to submit multiple superfluous requests
###
class InterstitialController < ApplicationController
  layout false

  before_action do
    render(file: 'public/500.html', status: :internal_server_error) unless redirect_param_same_as_host?
  end

  def show
    @redirect_to = URI.decode(params[:redirect_to])
  end

  private

  def redirect_param_same_as_host?
    return false if params[:redirect_to].blank?

    URI.parse(URI.decode(params[:redirect_to])).host == request.host
  end
end

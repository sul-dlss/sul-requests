# Page to display if something goes wrong with the request
# e.g. redirect from ILLiad logon or ScanAndDeliver pages
class SorryController < ApplicationController
  def unable
    @please_contact = please_contact
    render status: :internal_server_error
  end

  private

  def contact_info_config
    SULRequests::Application.config.contact_info
  end

  def contact_info
    contact_info_config['default']
  end

  def please_contact
    "Please contact the circulation desk in Green Library at
    #{contact_info[:email]} or #{contact_info[:phone]}."
  end
end

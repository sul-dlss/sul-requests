# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

SymphonyRequests::Application.configure do
   
  config.action_mailer.smtp_settings = {
     :address => 'smtp-unencrypted.stanford.edu',
     :domain  => 'stanford.edu'
  }  

end

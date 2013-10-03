# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
SymphonyRequests::Application.initialize!

#ActionMailer::Base.delivery_method = :smtp
#ActionMailer::Base.smtp_settings = {
# :address => 'smtp-unencrypted.stanford.edu',
# :domain  => 'stanford.edu'
#}

SymphonyRequests::Application.configure do
  
  config.action_mailer.smtp_settings = {
     :address => 'smtp-unencrypted.stanford.edu',
     :domain  => 'stanford.edu'
  }  
  
end

###
#  Top-level mailer class to allow us to set defaults like from and layout.
###
class ApplicationMailer < ActionMailer::Base
  default from: 'no-reply@requests.stanford.edu'
  layout 'mailer'
end

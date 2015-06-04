Rails.configuration.middleware.use(IsItWorking::Handler) do |h|
  # Check the ActiveRecord database connection without spawning a new thread
  h.check :active_record, async: false

  # Check the mail server configured for ActionMailer
  h.check :action_mailer if ActionMailer::Base.delivery_method == :smtp

  # Check that the web service is working by hitting a known URL with Basic authentication
  h.check :url, get: Settings.searchworks_api

  # ILLIAD doesn't provide an endpoint for us to test
  # h.check :url, get: Settings.sul_illiad + 'Action=10&Form=30&'
end

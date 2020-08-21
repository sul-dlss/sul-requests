# /status for 'upness', e.g. for load balancer
# /status/all to show all dependencies
# /status/<name-of-check> for a specific check (e.g. for nagios warning)
OkComputer.mount_at = 'status'
OkComputer.check_in_parallel = true

OkComputer::Registry.register 'confirmation_mailer', OkComputer::ActionMailerCheck.new(ConfirmationMailer)
OkComputer::Registry.register 'searchworks_api', OkComputer::HttpCheck.new("#{Settings.searchworks_api}/status")
OkComputer::Registry.register 'background_jobs', OkComputer::SidekiqLatencyCheck.new('default', 25)

if Settings.symphony_api.enabled && Settings.symphony_api.url.present?
  symphony_api_url = URI.parse(Settings.symphony_api.url)
  OkComputer::Registry.register(
    'symphony_api',
    OkComputer::PingCheck.new(
      symphony_api_url.host,
      symphony_api_url.port
    )
  )
end

###
# NON-Crucial (Optional) Checks
###

OkComputer::Registry.register 'hours_api', OkComputer::HttpCheck.new("#{Settings.hours_api}/status")
OkComputer::Registry.register 'sul_illiad', OkComputer::HttpCheck.new(Settings.sul_illiad)

OkComputer.make_optional %w(hours_api sul_illiad)

if Settings.symws.url
  symphony_web_services_url = URI.parse(Settings.symws.url)

  OkComputer::Registry.register(
    'symphony_web_services',
    OkComputer::PingCheck.new(
      symphony_web_services_url.host,
      symphony_web_services_url.port
    )
  )
  OkComputer.make_optional %w(symphony_web_services)
end

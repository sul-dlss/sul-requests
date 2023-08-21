# /status for 'upness', e.g. for load balancer
# /status/all to show all dependencies
# /status/<name-of-check> for a specific check (e.g. for nagios warning)
OkComputer.mount_at = 'status'
OkComputer.check_in_parallel = true

Rails.application.config.after_initialize do
  OkComputer::Registry.register 'request_status_mailer', OkComputer::ActionMailerCheck.new(RequestStatusMailer)
end
OkComputer::Registry.register 'searchworks_api', OkComputer::HttpCheck.new("#{Settings.searchworks_api}/status")
OkComputer::Registry.register 'background_jobs', OkComputer::SidekiqLatencyCheck.new('default', 25)

###
# NON-Crucial (Optional) Checks
###

OkComputer::Registry.register 'hours_api', OkComputer::HttpCheck.new("#{Settings.hours_api}/status")
OkComputer::Registry.register 'sul_illiad', OkComputer::HttpCheck.new(Settings.sul_illiad)

OkComputer.make_optional %w[hours_api sul_illiad]

if Settings.folio.graphql_url || Settings.folio.okapi_url
  okapi_uri = URI.parse(Settings.folio.okapi_url)
  OkComputer::Registry.register(
    'okapi',
    OkComputer::PingCheck.new(
      okapi_uri.host,
      okapi_uri.port
    )
  )

  graphql_uri = URI.parse(Settings.folio.graphql_url)
  OkComputer::Registry.register(
    'graphql',
    OkComputer::PingCheck.new(
      graphql_uri.host,
      graphql_uri.port
    )
  )
  OkComputer.make_optional %w[okapi graphql]
end
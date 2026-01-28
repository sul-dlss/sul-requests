# /status for 'upness', e.g. for load balancer
# /status/all to show all dependencies
# /status/<name-of-check> for a specific check (e.g. for nagios warning)
OkComputer.mount_at = 'status'
OkComputer.check_in_parallel = true

Rails.application.config.after_initialize do
  OkComputer::Registry.register 'patron_request_mailer', OkComputer::ActionMailerCheck.new(PatronRequestMailer)
end
OkComputer::Registry.register 'background_jobs', OkComputer::SidekiqLatencyCheck.new('default', 25)

###
# NON-Crucial (Optional) Checks
###

OkComputer::Registry.register 'hours_api', OkComputer::HttpCheck.new("#{Settings.hours_api}/status")
OkComputer::Registry.register 'sul_illiad', OkComputer::HttpCheck.new(Settings.sul_illiad)

# Check Folio by calling ping on the client
class OkapiCheck < OkComputer::Check
  def check
    if FolioClient.new.ping
      mark_message 'Connected to OKAPI'
    else
      mark_failure
      mark_message 'Unable to connect to OKAPI'
    end
  rescue # FolioClient raises when response is not 200
    mark_failure
    mark_message 'OKAPI not responding with 200'
  end
end

# Check Folio GraphQL by calling ping on the client
class GraphqlCheck < OkComputer::Check
  def check
    if FolioGraphqlClient.new.ping
      mark_message 'Connected to Folio GraphQL'
    else
      mark_failure
      mark_message 'Unable to connect to Folio GraphQL'
    end
  end
end

OkComputer::Registry.register('okapi', OkapiCheck.new) if Settings.folio.okapi_url
OkComputer::Registry.register('graphql', GraphqlCheck.new) if Settings.folio.graphql_url
OkComputer.make_optional %w[okapi graphql hours_api sul_illiad]

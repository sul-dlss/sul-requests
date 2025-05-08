ActiveSupport::Notifications.subscribe('request.folio') do |name, start, finish, id, payload|
  Rack::MiniProfiler.counter('request.folio graphql', (finish.to_f - start.to_f) * 1000)
end

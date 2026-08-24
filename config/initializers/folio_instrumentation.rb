# frozen_string_literal: true

# Throwaway diagnostic for the 60s homepage render on dev/stage/prod.
# Everything it emits is tagged [DEBUG-perf], so `grep -v '\[DEBUG-perf\]'` removes it
# from a log and deleting this file removes it from the app.
#

module DebugPerf
  THRESHOLD_MS = Integer(ENV.fetch('SLOW_RENDER_MS', 250))

  def self.log(message)
    Rails.logger.info("[DEBUG-perf] #{message}")
  end

  # Per-request accumulator, so we can compare total external HTTP time against
  # the request's own duration. A big gap means the time is not in HTTP.
  def self.reset!
    Thread.current[:debug_perf_http_ms] = 0.0
    Thread.current[:debug_perf_http_count] = 0
  end

  def self.record(ms)
    Thread.current[:debug_perf_http_ms] = http_ms + ms
    Thread.current[:debug_perf_http_count] = http_count + 1
  end

  def self.http_ms = Thread.current[:debug_perf_http_ms] || 0.0
  def self.http_count = Thread.current[:debug_perf_http_count] || 0
end

# --- Every Faraday call: FOLIO REST, Aeon, Illiad, finding aid ------------------
# run_request is the single chokepoint for all four clients, so this needs no
# per-client patching and cannot miss a connection built elsewhere.
Rails.application.config.to_prepare do
  Faraday::Connection.prepend(Module.new do
    def run_request(method, url, body, headers)
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      super
    ensure
      ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000
      DebugPerf.record(ms)
      target = begin
        url_prefix.merge(url.to_s)
      rescue StandardError
        url.to_s
      end
      DebugPerf.log(format('faraday %8.1fms %s %s', ms, method.to_s.upcase, target))
    end
  end)
end

# --- HTTP.rb calls: the FOLIO GraphQL client ------------------------------------
# FolioGraphqlClient passes namespace: 'folio', and http-instrumentation builds the
# event name as "request.#{namespace}". So the events are request.folio and
# error.folio, NOT request.folio_graphql.
ActiveSupport::Notifications.subscribe('request.folio') do |_name, start, finish, _id, payload|
  ms = (finish - start) * 1000
  DebugPerf.record(ms)
  request = payload[:request]
  DebugPerf.log(format('http.rb %8.1fms %s %s -> %s', ms, request&.verb&.to_s&.upcase,
                       request&.uri, payload[:response]&.status))
end

# Fires once per failed attempt inside with_retries, which is the only way to see
# the retry loop. The sleep sits outside `request`, so it appears in no timing event.
ActiveSupport::Notifications.subscribe('error.folio') do |_name, _start, _finish, _id, payload|
  DebugPerf.log("http.rb ERROR #{payload[:error].class}: #{payload[:error].message} " \
                "(#{payload[:request]&.uri})")
end

# --- Which template or partial holds the time -----------------------------------
# These fire regardless of log level, so this localizes the 60s to one partial or
# component without turning on full debug logging on a shared server.
%w[render_template.action_view render_partial.action_view
   render_layout.action_view].each do |event|
  ActiveSupport::Notifications.subscribe(event) do |name, start, finish, _id, payload|
    ms = (finish - start) * 1000
    next if ms < DebugPerf::THRESHOLD_MS

    DebugPerf.log(format('%-28s %8.1fms %s', name.split('.').first, ms,
                         payload[:identifier] || payload[:virtual_path]))
  end
end

# --- Request summary ------------------------------------------------------------
ActiveSupport::Notifications.subscribe('start_processing.action_controller') do
  DebugPerf.reset!
end

ActiveSupport::Notifications.subscribe('process_action.action_controller') do |_n, start, finish, _id, payload|
  total_ms = (finish - start) * 1000
  http_ms = DebugPerf.http_ms
  DebugPerf.log(format('SUMMARY %s#%s total=%.1fms http=%.1fms (%d calls) unaccounted=%.1fms',
                       payload[:controller], payload[:action], total_ms, http_ms,
                       DebugPerf.http_count, total_ms - http_ms))
end

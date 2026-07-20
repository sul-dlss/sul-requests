# frozen_string_literal: true

# If an exception defines #to_honeybadger_context (e.g. AeonClient::ApiError),
# fold its return value into the Honeybadger notice so unrescued errors still
# surface their request/response details.
Honeybadger.configure do |config|
  config.before_notify do |notice|
    if Rails.env.development?
      Rails.logger.error("[Honeybadger] #{notice.error_class}: #{notice.error_message}\n#{notice.backtrace&.join("\n")}")
      notice.halt!
    else
      notice.context.merge!(notice.exception.to_honeybadger_context) if notice.exception.respond_to?(:to_honeybadger_context)
    end
  end
end

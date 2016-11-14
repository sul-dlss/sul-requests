if Settings.background_jobs && Settings.background_jobs.enabled
  Sidekiq.configure_client do |config|
    Sidekiq.logger.level = Settings.background_jobs.log_level.constantize if Settings.background_jobs.log_level
  end
end

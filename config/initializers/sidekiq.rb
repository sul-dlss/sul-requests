if Settings.background_jobs && Settings.background_jobs.enabled
  Sidekiq.configure_client do |config|
    Sidekiq::Logging.initialize_logger(Settings.background_jobs.logfile) if Settings.background_jobs.logfile
    Sidekiq.logger.level = Settings.background_jobs.log_level.constantize if Settings.background_jobs.log_level
  end
end

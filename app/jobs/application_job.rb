# frozen_string_literal: true

# :nodoc:
class ApplicationJob < ActiveJob::Base
  def cdl_logger(*args)
    Rails.logger.tagged('CDL') do
      Rails.logger.info(*args)
    end
  end
end

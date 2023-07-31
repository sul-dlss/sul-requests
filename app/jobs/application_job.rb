# frozen_string_literal: true

# :nodoc:
class ApplicationJob < ActiveJob::Base
  def cdl_logger(*)
    Rails.logger.tagged('CDL') do
      Rails.logger.info(*)
    end
  end
end

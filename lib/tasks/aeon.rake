# frozen_string_literal: true

namespace :aeon do
  task check_for_upcoming_requests_for_the_same_item: :environment do
    CheckForUpcomingAeonRequestsForTheSameItemJob.perform_later
  end
end

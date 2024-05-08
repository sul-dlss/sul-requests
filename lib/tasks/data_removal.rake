# frozen_string_literal: true

namespace :data_removal do
  desc 'Remove old requests'
  task remove_old_requests: :environment do
    t = ActiveSupport::Duration.build(Settings.data_cleanup.age).ago
    raise 'Date is too recent' if t > 1.month.ago

    Request.obsolete(t).delete_all

    PatronRequest.obsolete(t).delete_all
  end
end

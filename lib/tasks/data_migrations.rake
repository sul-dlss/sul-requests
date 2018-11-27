# frozen_string_literal: true

namespace :data_migration do
  desc "Update all item's approval status whose needed_date has passed as either done or approved"
  task mark_all_archived_mediated_pages_as_complete: :environment do
    MediatedPage.mark_all_archived_as_complete!
  end
end

# frozen_string_literal: true

# Helpers used in views/archives_requests for rendering EAD data and generating form values/IDs
module ArchivesRequestsHelper
  # Generate a volume value hash for form submission
  def volume_value(series_title:, subseries_name:)
    {
      series: series_title.truncate(30),
      subseries: subseries_name
    }.to_json
  end

  # Generate a unique checkbox ID for a volume
  def volume_checkbox_id(series_title:, subseries_name:)
    "volumes_#{series_title.truncate(30).parameterize}_#{subseries_name.parameterize}"
  end

  # Generate a unique ID for collapsible content
  def collapsible_content_id(prefix:, series_title:, item_name:, index: nil)
    parts = [prefix, series_title.parameterize, item_name.parameterize]
    parts << index if index
    parts.join('-')
  end
end

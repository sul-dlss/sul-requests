# frozen_string_literal: true

# Helpers used in views/archives_requests for rendering EAD data and generating form values/IDs
module EadRequestsHelper
  # Generate a unique checkbox ID for a volume
  def volume_checkbox_id(*hierarchy)
    "volumes_#{hierarchy.map { |x| x.truncate(30).parameterize }.join('_')}"
  end

  # Generate a unique ID for collapsible content
  def collapsible_content_id(prefix:, hierarchy: [], index: nil)
    [prefix, hierarchy.map(&:parameterize), index].compact.flatten.join('-')
  end
end

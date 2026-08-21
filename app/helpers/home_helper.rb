# frozen_string_literal: true

# Helpers for the home page redesign views.
module HomeHelper
  def activities_card_label(in_progress:, upcoming:)
    return t('dashboard.activities.label_html', count: upcoming) if in_progress.zero?
    return t('dashboard.activities.in_progress_label_html', count: in_progress) if upcoming.zero?

    t('dashboard.activities.in_progress_with_upcoming_label_html', in_progress:, upcoming:)
  end
end

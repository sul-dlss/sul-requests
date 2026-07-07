# frozen_string_literal: true

###
#  Helper module for stuff ported over from from mylibrary
###
module MylibraryHelper
  # Return a nice, human-readable date (for e.g. a due date or request deadline)
  # For short-term loans, also include the time.
  def today_with_time_or_date(date, short_term: false)
    return unless date

    return l(date, format: :time_today) if short_term && date.today?
    return l(date, format: :time_tomorrow) if short_term && date.to_date == Time.zone.tomorrow

    format_human_readable_date(date)
  end

  # Format a date as 'human readable' by showing today/yesterday/tomorrow,
  # as appropriate, and otherwise falling back on an actual date display
  def format_human_readable_date(date)
    case date.to_date
    when Time.zone.today.to_date
      'Today'
    when Time.zone.tomorrow
      'Tomorrow'
    when Time.zone.yesterday
      'Yesterday'
    else
      l(date, format: :date_only)
    end
  end

  def format_relative_date_phrase(date)
    return unless date

    days = (date.to_date - Time.zone.today).to_i
    case days
    when 0 then 'today'
    when 1 then 'tomorrow'
    when -1 then 'yesterday'
    when 2..7 then "in #{pluralize(days, 'day')}"
    when -7..-2 then "#{pluralize(-days, 'day')} ago"
    else l(date, format: :date_only)
    end
  end

  # Wrap a link to the SearchWorks record for the given Catkey wrapped in the markup
  # necessary to be aligned with the content in the collapsible list sections
  def detail_link_to_searchworks(catkey)
    return if catkey.blank?

    link_to "#{Settings.searchworks_link}/#{catkey}", rel: 'noopener', target: '_blank', class: 'su-underline' do
      safe_join(['View in SearchWorks', tag.i(class: 'ms-1 bi bi-arrow-up-right')])
    end
  end
end

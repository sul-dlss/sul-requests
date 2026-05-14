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

  # Wrap a link to the SearchWorks record for the given Catkey wrapped in the markup
  # necessary to be aligned with the content in the collapsible list sections
  def detail_link_to_searchworks(catkey)
    return if catkey.blank?

    tag.div(class: 'row') do
      tag.div(class: 'col-11 offset-1 col-md-10 offset-md-2') do
        link_to "#{Settings.searchworks_link}/#{catkey}", rel: 'noopener', target: '_blank' do
          sul_icon(:'sharp-open_in_new-24px') + ' View in SearchWorks' # rubocop:disable Style/StringConcatenation
        end
      end
    end
  end

  ##
  # Returns the raw SVG (String) for a SUL Icon located in
  # app/assets/images/icons/*.svg. Caches them so we don't have to look up
  # the svg everytime.
  # @param [String, Symbol] icon_name
  # @return [String]
  def sul_icon(icon_name, **kwargs)
    Rails.cache.fetch([:sul_icon, icon_name, kwargs]) do
      icon = Icon.new(icon_name, **kwargs)
      tag.span(icon.svg.html_safe, **icon.options) # rubocop:disable Rails/OutputSafety
    end
  end
end

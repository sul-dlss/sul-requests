# frozen_string_literal: true

# Helpers used in views/archives_requests for rendering EAD data and generating form values/IDs
module EadRequestsHelper
  def access_restrictions_label(level)
    case level
    when 'collection' then 'Collection restrictions'
    when 'series', 'subseries' then 'Series restrictions'
    when 'file' then 'File restrictions'
    when 'item' then 'Item restrictions'
    else 'Access restrictions'
    end
  end

  # Translate EAD note markup to a small, sanitized subset of HTML.
  def access_note_body(note, paragraph_class: 'mb-last-child-0')
    body = note.dup
    body.xpath('head').remove
    body.xpath('.//extref').each { |link| link.name = 'a' }
    body.xpath('.//title').each { |title| title.name = 'em' }
    body.xpath('.//p').each { |paragraph| paragraph['class'] = paragraph_class }
    sanitize(body.inner_html, tags: %w[p a em strong br], attributes: %w[href class])
  end

  # Generate a unique checkbox ID for a volume
  def volume_checkbox_id(*hierarchy)
    "volumes_#{hierarchy.map { |x| x.truncate(30).parameterize }.join('_')}"
  end

  # Generate a unique ID for collapsible content
  def collapsible_content_id(prefix:, hierarchy: [], index: nil)
    [prefix, hierarchy.map(&:parameterize), index].compact.flatten.join('-')
  end
end

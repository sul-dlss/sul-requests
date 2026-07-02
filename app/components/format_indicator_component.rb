# frozen_string_literal: true

# Renders the "format icon + document_type text" pair used across FOLIO, Aeon,
# and EAD record displays. Icon comes from the SUL_ICON_COMPONENTS lookup,
# falling back to DocumentBox1Component when no format string matches.
class FormatIndicatorComponent < ViewComponent::Base
  delegate :render_resource_icon, to: :helpers

  def initialize(record:)
    @record = record
  end

  def render?
    @record.document_type.present?
  end

  def call
    tag.span(safe_join([
                         tag.span(icon, class: 'me-1 align-text-bottom'),
                         @record.document_type
                       ]))
  end

  private

  def icon
    render_resource_icon(icon_values) || render(Icons::DocumentBox1Component.new)
  end

  def icon_values
    @record.respond_to?(:document_formats) ? @record.document_formats : @record.document_type
  end
end

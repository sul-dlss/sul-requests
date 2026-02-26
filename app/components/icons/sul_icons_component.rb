# frozen_string_literal: true

module Icons
  # Copied + adapted from Searchworks' Icons::SulIconsComponent and Blacklgiht's Blacklight::Icons::IconComponent
  class SulIconsComponent < ViewComponent::Base
    attr_reader :classes

    # rubocop:disable Metrics/ParameterLists
    def initialize(svg: nil, tag: :span, name: nil, label: nil, aria_hidden: nil, classes: nil, **options)
      self.svg = svg if svg
      @name = name
      @classes = Array(classes)
      @tag = tag
      @options = options.merge(aria: options.fetch(:aria, {}).reverse_merge(label: label, hidden: aria_hidden))
    end
    # rubocop:enable Metrics/ParameterLists

    def call
      tag.public_send(@tag, svg&.html_safe, # rubocop:disable Rails/OutputSafety
                      class: classes,
                      **@options)
    end

    class_attribute :svg
  end
end

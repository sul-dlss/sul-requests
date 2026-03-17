# frozen_string_literal: true

module Aeon
  # Render request link
  class RequestLinkComponent < ViewComponent::Base
    def initialize(url:)
      @item_url = url
    end

    def render?
      link_text.present?
    end

    def call
      return if link_text.blank?

      link_to @item_url, class: 'su-underline', target: '_blank', rel: 'noopener' do
        safe_join([link_text, tag.i(class: 'ms-1 bi bi-arrow-up-right')])
      end
    end

    def link_text
      return unless @item_url.match?('/archives.stanford.edu/') || @item_url.match?('/searchworks.stanford.edu/')

      if @item_url.match?('/archives.stanford.edu/')
        'View in Archival Collections at Stanford'
      elsif @item_url.match?('/searchworks.stanford.edu/')
        'View in Searchworks'
      end
    end
  end
end

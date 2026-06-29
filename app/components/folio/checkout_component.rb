# frozen_string_literal: true

module Folio
  # Render a single checkout for a patron
  class CheckoutComponent < ViewComponent::Base
    attr_reader :checkout, :patron, :renewal_view

    delegate :sul_icon, :today_with_time_or_date, :detail_link_to_searchworks, to: :helpers

    delegate :renewable?, :lost?, :recalled?, :renewal_blocked_by_hold?, :claimed_returned?, :unseen_renewals_remaining, :renewal_count,
             :reserve_item?, :location, :too_soon_to_renew?, :item_category_non_renewable?, to: :checkout, private: true

    def initialize(checkout:, patron:, renewal_view: false)
      @checkout = checkout
      @patron = patron
      @renewal_view = renewal_view
      super()
    end

    def non_renewable_reason
      return 'Assumed lost' if lost?
      return 'Renew' if recalled? || renewal_blocked_by_hold?
      return 'Claim review is in process' if claimed_returned?
      return 'Renew in person' if reserve_item?
      return 'Too soon to renew' if too_soon_to_renew?

      'Renew'
    end

    def header_message
      return 'Please return as soon as possible. Item cannot be renewed.' if recalled? || renewal_blocked_by_hold?
      return accruing_message if checkout.overdue?
      return unless reserve_item? && location&.library

      "NOTE: This item must be returned to the #{location.library.primary_service_points.first.name}"
    end

    def accruing_message
      return unless checkout.accruing?

      "Accruing #{number_to_currency(checkout.overdue_fines_rate['quantity'])}/#{checkout.overdue_fines_rate['intervalId']} until returned"
    end

    def status_pill_html # rubocop:disable Metrics/AbcSize
      return safe_join([tag.i(class: 'bi bi-exclamation-triangle me-1'), 'Recalled']) if checkout.recalled?
      return safe_join([tag.i(class: 'bi bi-exclamation-triangle me-1'), 'Overdue']) if checkout.overdue?
      return safe_join([tag.i(class: 'bi bi-exclamation-triangle me-1'), 'Assumed lost']) if checkout.lost?

      safe_join([tag.i(class: 'bi'), 'Processing claim']) if checkout.claimed_returned?
    end

    def proxy_borrower
      return nil unless checkout.proxy_checkout?

      patron.proxies.find(checkout.patron_key)
    end

    def checkout_status_pill
      return unless status_pill_html

      pill_classes = if checkout.claimed_returned?
                       %w[text-warning bg-warning-subtle
                          text-nowrap]
                     else
                       %w[text-digital-red-dark bg-digital-red-10 text-nowrap]
                     end
      render PillComponent.new(classes: pill_classes).with_content(status_pill_html)
    end

    def contact_email
      checkout.contact_info&.dig(:email)
    end

    def cover_image
      identifiers = checkout.identifiers

      tag.img class: "cover-image center-block #{identifiers.values.flatten.join(' ')}",
              hidden: true,
              alt: '',
              data: {
                google_cover_image_target: 'image',
                isbn: identifiers['ISBN']&.join(','),
                oclc: identifiers['OCLC']&.join(','),
                lccn: identifiers['LCCN']&.join(',')
              }
    end

    private

    def checkout_status_html(text:, css_class: nil, icon: nil, accrued: 0)
      tag.span(class: css_class) do
        safe_join([
                    (sul_icon(icon) if icon),
                    text,
                    (number_to_currency(accrued) if accrued.positive?)

                  ], ' ')
      end
    end
  end
end

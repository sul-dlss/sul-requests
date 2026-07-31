# frozen_string_literal: true

module Folio
  # Render a single checkout for a patron
  class CheckoutComponent < ViewComponent::Base
    attr_reader :checkout, :patron, :renewal_view

    delegate :today_with_time_or_date, :detail_link_to_searchworks, to: :helpers

    delegate :renewable?, :lost?, :recalled?, :renewal_blocked_by_hold?, :claimed_returned?, :unseen_renewals_remaining, :renewal_count,
             :reserve_item?, :location, :too_soon_to_renew?, :item_category_non_renewable?, to: :checkout, private: true

    def initialize(checkout:, patron:, renewal_view: false)
      @checkout = checkout
      @patron = patron
      @renewal_view = renewal_view
      super()
    end

    def non_renewable_reason
      return 'Too soon to renew' if too_soon_to_renew? && header_message.blank?

      'Renew'
    end

    def header_message # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      @header_message ||= 'This item was requested by another user. Please return as soon as possible.' if recalled? || renewal_blocked_by_hold? # rubocop:disable Layout/LineLength
      @header_message ||= accruing_message if checkout.accruing?
      @header_message ||= 'You reported this item as returned. Library staff are reviewing its status.' if checkout.claimed_returned?
      @header_message ||= 'This overdue item is assumed lost.' if checkout.lost?
      @header_message ||= 'This is a reserve item. Renew in person.' if reserve_item?
      @header_message ||= 'Renewals are not allowed.' if checkout.item_category_non_renewable?
      @header_message ||= 'Online renewals are not allowed. Renew in person.' unless checkout.unseen_renewals_allowed?
      @header_message ||= 'No online renewals remain. Renew in person.' if unseen_renewals_remaining.zero?

      @header_message
    end

    def specific_return_location_message
      return unless reserve_item? && location&.library

      "NOTE: This item must be returned to the #{location.library.primary_service_points.first.name}"
    end

    def accruing_message
      return unless checkout.accruing?

      "Accruing #{number_to_currency(checkout.overdue_fines_rate['quantity'])}/#{checkout.overdue_fines_rate['intervalId']} until returned"
    end

    def status_pill_html
      return safe_join([tag.i(class: 'bi bi-exclamation-triangle me-1'), 'Recalled']) if checkout.recalled?
      return safe_join([tag.i(class: 'bi bi-exclamation-triangle me-1'), 'Overdue']) if checkout.overdue? || checkout.lost?

      nil
    end

    def proxy_borrower
      return nil unless checkout.proxy_checkout?

      patron.proxies.find(checkout.patron_key)
    end

    def checkout_status_pill
      return unless status_pill_html

      render PillComponent.new(classes: %w[text-digital-red-dark bg-digital-red-10 text-nowrap]).with_content(status_pill_html)
    end

    def contact_email
      checkout.contact_info&.dig(:email)
    end
  end
end

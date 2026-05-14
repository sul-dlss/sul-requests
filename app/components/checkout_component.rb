# frozen_string_literal: true

# Render a single checkout for a patron
class CheckoutComponent < ViewComponent::Base
  attr_reader :checkout, :patron

  delegate :sul_icon, :today_with_time_or_date, :detail_link_to_searchworks, to: :helpers

  delegate :renewable?, :lost?, :recalled?, :renewal_blocked_by_hold?, :claimed_returned?, :unseen_renewals_remaining, :renewal_count,
           :reserve_item?, :too_soon_to_renew?, :item_category_non_renewable?, to: :checkout, private: true

  def initialize(checkout:, patron:)
    @checkout = checkout
    @patron = patron
    super()
  end

  # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
  def non_renewable_reason
    return 'Item is assumed lost; you must pay the fee or return the item.' if lost?
    return 'Another user is waiting for this item.' if recalled? || renewal_blocked_by_hold?
    return 'Claim review is in process.' if claimed_returned?

    unless unseen_renewals_remaining.positive?
      return 'No online renewals left; you may renew this item in person.' if renewal_count.positive?

      return 'No online renewals for this item.'
    end

    return 'Renew Reserve items in person.' if reserve_item?
    return 'Another user is waiting for this item.' if item_category_non_renewable?

    'Too soon to renew.' if too_soon_to_renew?
  end
  # rubocop:enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def render_checkout_status
    if checkout.recalled?
      checkout_status_html(css_class: 'text-recalled',
                           icon: 'sharp-error-24px',
                           text: 'Recalled',
                           accrued: checkout.accrued)
    elsif checkout.claimed_returned?
      checkout_status_html(text: 'Processing claim')
    elsif checkout.lost?
      checkout_status_html(css_class: 'text-lost',
                           icon: 'sharp-warning-24px',
                           text: 'Assumed lost',
                           accrued: checkout.accrued)
    elsif checkout.overdue?
      checkout_status_html(css_class: 'text-overdue',
                           icon: 'sharp-warning-24px',
                           text: 'Overdue',
                           accrued: checkout.accrued)
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

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

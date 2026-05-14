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

  def non_renewable_reason
    return 'Assumed lost' if lost?
    return 'Another user is waiting' if recalled? || renewal_blocked_by_hold?
    return 'Claim review is in process' if claimed_returned?
    return 'Renew in person' if reserve_item?
    return 'Too soon to renew' if too_soon_to_renew?

    'Renew'
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def checkout_status_pill
    if checkout.recalled?
      tag.span class: 'small fw-bold rounded-pill text-digital-red-dark bg-danger-subtle py-1 px-2' do
        safe_join([tag.i(class: 'bi bi-exclamation-triangle me-1'), 'Recalled'])
      end
    elsif checkout.overdue?
      tag.span class: 'small fw-bold rounded-pill text-digital-red-dark bg-danger-subtle py-1 px-2' do
        safe_join([tag.i(class: 'bi bi-exclamation-triangle me-1'), 'Overdue'])
      end
    elsif checkout.lost?
      tag.span class: 'small fw-bold rounded-pill text-digital-red-dark bg-danger-subtle py-1 px-2' do
        safe_join([tag.i(class: 'bi bi-exclamation-triangle me-1'), 'Assumed lost'])
      end
    elsif checkout.claimed_returned?
      tag.span class: 'small fw-bold rounded-pill text-warning bg-warning-subtle py-1 px-2' do
        safe_join([tag.i(class: 'bi'), 'Processing claim'])
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def contact_email
    contact_info = Settings.locations[checkout.effective_location_code]&.contact_info ||
                   Settings.libraries[checkout.library_code]&.contact_info

    contact_info&.dig(:email)
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

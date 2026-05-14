# frozen_string_literal: true

# Render a single checkout for a patron
class CheckoutComponent < ViewComponent::Base
  attr_reader :checkout, :patron

  delegate :sul_icon, :today_with_time_or_date, :detail_link_to_searchworks, to: :helpers

  def initialize(checkout:, patron:)
    @checkout = checkout
    @patron = patron
    super()
  end

  def list_group_item_status_for_checkout
    if checkout.recalled?
      'list-group-item-danger'
    elsif checkout.overdue?
      'list-group-item-warning'
    end
  end

  def time_remaining_for_checkout
    return pluralize(checkout.days_remaining, 'day') unless checkout.short_term_loan?

    distance_of_time_in_words(Time.zone.now, checkout.due_date) if checkout.due_date
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

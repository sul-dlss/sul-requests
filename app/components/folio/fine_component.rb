# frozen_string_literal: true

# Render a single fine or payment for a patron
class FineComponent < ViewComponent::Base
  attr_reader :fine, :sortable, :patron

  delegate :detail_link_to_searchworks, to: :helpers

  def initialize(fine:, sortable: false, patron: nil)
    @fine = fine
    @sortable = sortable
    @patron = patron
    super()
  end

  def proxy_borrower
    return nil unless fine.proxy_checkout?

    patron.proxies.find(fine.patron_key)
  end

  def data
    return {} unless sortable

    { status_sort_value: fine.sort_key(:status_label), fee_sort_value: fine.sort_key(:fee),
      data_sort_value: fine.sort_key(:payment_date), title_sort_value: fine.sort_key(:title) }
  end

  def checked_out?
    fine.is_a?(Folio::Checkout)
  end

  def body_title
    return fine.title if checked_out?

    case fine.fine_type
    when 'SUL library card'
      'Lost library card'
    else
      fine.title
    end
  end
end

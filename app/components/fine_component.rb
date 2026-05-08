class FineComponent < ViewComponent::Base
  attr_reader :fine, :patron

  delegate :sul_icon, :detail_link_to_searchworks, to: :helpers

  def initialize(fine:, patron:)
    @fine = fine
    @patron = patron
    super()
  end

  def nice_status_fee_label
    status = fine.nice_status

    return status if status.ends_with?('fee')

    "#{status} fee"
  end

  def contact_path(*, **)
    '#'
  end
end

# frozen_string_literal: true

###
#  Controller to handle particular behaviors for MediatedPage type requests
###
class MediatedPagesController < RequestsController
  before_action :check_if_proxy_sponsor, only: :create

  def update
    respond_to do |format|
      if current_request.update(update_params)
        format.js { render json: current_request }
      else
        format.js { render json: { status: :error }, status: :bad_request }
      end
    end
  end

  protected

  def validate_eligibility
    return unless Settings.features.validate_eligibility
    return if can?(:manage, current_request)
    return if current_user_affiliated_or_grad_student?

    redirect_to polymorphic_path(
      [:ineligible, current_request],
      request_context_params.merge(origin: current_request.origin)
    )
  end

  def validate_patron_standing; end

  def current_user_affiliated_or_grad_student?
    valid_affiliation = current_user.affiliation.any? { |aff| Settings.mediated_paging_eligible_groups.include?(aff) }
    grad_student = current_user.affiliation.include?('stanford:student') && current_user.student_type.include?('graduate')

    valid_affiliation || grad_student
  end

  def update_params
    params.require(:mediated_page).permit(:approval_status, :needed_date)
  end

  def send_confirmation
    current_request.send_confirmation!
  end

  def validate_request_type
    raise UnmediateableItemError unless current_request.mediateable?
  end

  class UnmediateableItemError < StandardError
  end
end

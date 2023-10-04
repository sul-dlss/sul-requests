# frozen_string_literal: true

###
#  Controller to handle particular behaviors for MediatedPage type requests
###
class MediatedPagesController < RequestsController
  before_action :check_if_proxy_sponsor, only: :create

  def update # rubocop:disable Metrics:MethodLength
    respond_to do |format|
      if current_request.update(update_params)
        format.turbo_stream do
          if current_request.approval_status == 'marked_as_done'
            render turbo_stream: turbo_stream.replace('mediate-status', partial: 'admin/mediate_status',
                                                                        locals: { request: current_request }) +
                                 turbo_stream.replace('mark-as-complete', partial: 'admin/mark_as_complete',
                                                                          locals: { request: current_request })
          end
        end
      else
        format.html do
          redirect_back flash: { error: 'There was a problem marking this request as complete.' },
                        fallback_location: root_url,
                        status: :unprocessable_entity
        end
      end
    end
  end

  protected

  def update_params
    params.require(:request).permit(:approval_status)
  end

  def validate_request_type
    return if current_request.mediateable? || (Settings.features.migration && current_request.pageable? && params[:action] == 'update')

    raise UnmediateableItemError
  end

  class UnmediateableItemError < StandardError
  end
end

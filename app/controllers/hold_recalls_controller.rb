###
#  Controller to handle particular behaviors for HoldRecall type requests
###
class HoldRecallsController < RequestsController
  def new
    request_defaults(@hold_recall)
    validate_hold_recallable
  end

  def create
    if @hold_recall.update(create_params_with_current_user)
      @hold_recall.send_confirmation!
      redirect_to_success_with_token(@hold_recall)
    else
      flash[:error] = 'There was a problem creating your request.'
      render 'new'
    end
  end

  def current_request
    @hold_recall ||= HoldRecall.new
  end

  protected

  def rescue_can_can(*)
    if !current_user.webauth_user? && create_via_post?
      redirect_to login_path(
        referrer: create_hold_recalls_path(
          hold_recall: local_object_param.except(:user_attributes)
        )
      )
    else
      super
    end
  end

  def create_params
    params.require(:hold_recall).permit(:destination,
                                        :item_id,
                                        :origin,
                                        :origin_location,
                                        :needed_date,
                                        :item_comment,
                                        :request_comment,
                                        barcodes: [],
                                        user_attributes: [:name, :email, :library_id])
  end

  def local_object_param
    params[:hold_recall]
  end

  def validate_hold_recallable
    fail NotHoldRecallableError unless @hold_recall.hold_recallable?
  end

  class NotHoldRecallableError < StandardError
  end
end

##
# Controller to handle the creation of admin comments on requests
class AdminCommentsController < ApplicationController
  load_and_authorize_resource :mediated_page
  load_and_authorize_resource :admin_comment, through: :mediated_page

  def create
    respond_to do |format|
      if @admin_comment.save
        format.html { redirect_to :back, notice: 'Comment was successfully created.' }
        format.js   { render json: @admin_comment }
      else
        format.html { redirect_to :back, flash: { error: 'There was an error creating your comment.' } }
        format.js   { render json: { status: :error }, status: :bad_request }
      end
    end
  end

  protected

  def create_params
    params.require(:admin_comment).permit(:comment).to_h.merge(commenter: current_user.webauth)
  end
end

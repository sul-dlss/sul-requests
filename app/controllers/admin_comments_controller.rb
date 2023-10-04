# frozen_string_literal: true

##
# Controller to handle the creation of admin comments on requests
class AdminCommentsController < ApplicationController
  load_and_authorize_resource :mediated_page
  load_and_authorize_resource :admin_comment, through: :mediated_page

  def create # rubocop:disable Metrics:MethodLength
    respond_to do |format|
      if @admin_comment.save
        format.turbo_stream do
          render turbo_stream: turbo_stream.append('admin-comments-list', partial: 'admin_comments/admin_comment',
                                                                          locals: { admin_comment: @admin_comment })
        end
        format.html { redirect_back notice: 'Comment was successfully created.', fallback_location: root_url }
      else
        format.html do
          redirect_back flash: { error: 'There was an error creating your comment.' }, fallback_location: root_url,
                        status: :unprocessable_entity
        end
      end
    end
  end

  protected

  def create_params
    params.require(:admin_comment).permit(:comment).to_h.merge(commenter: current_user.sunetid)
  end
end

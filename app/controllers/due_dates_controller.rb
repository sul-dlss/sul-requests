# frozen_string_literal: true

##
# Controller to display the due date in a lazy way, because getting due dates in the graphQL query
# with all the other item data was too slow.
class DueDatesController < ApplicationController
  def show
    instance_id = params[:id]
    due_dates = FolioClient.new.due_date(instance_id:)
    render partial: 'show', locals: { due_dates: }
  end
end

# frozen_string_literal: true

##
# Controller to display the due date in a lazy way, because getting due dates in the graphQL query
# with all the other item data was too slow.
class DueDatesController < ApplicationController
  def show
    item_id = params[:id]
    due_date = FolioClient.new.due_date(item_id:).to_date
    render partial: 'show', locals: { due_date:, item_id: }
  end
end

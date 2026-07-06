# frozen_string_literal: true

###
#  A user's mediated requests (that haven't been placed in FOLIO yet)
###
class MediatedRequestsController < ApplicationController
  before_action :load_requests

  def index
    render 'async' and return if params[:async]
  end

  def load_requests
    @requests = PatronRequest.unapproved.where(user: current_user)
  end
end

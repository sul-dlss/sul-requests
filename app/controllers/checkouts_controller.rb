# frozen_string_literal: true

# Controller for the Checkouts page
class CheckoutsController < ApplicationController
  before_action :authenticate_user!

  helper_method :patron_or_group

  # Render a list of checkouts for the patron
  #
  # GET /checkouts
  # GET /checkouts.json
  def index
    @checkouts = patron_or_group.checkouts.sort_by { |x| x.sort_key(:due_date) }
  end

  private

  def patron_or_group
    current_user.patron
  end

  def authenticate_user!
    redirect_to root_url unless current_user?
  end
end

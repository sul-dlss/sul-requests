# frozen_string_literal: true

# Controller for the Fines and Fees page
class FinesController < ApplicationController
  include FolioController

  before_action :authenticate_user!

  # Render a patron or groups fines or checkouts
  #
  # GET /fines
  # GET /fines.json
  def index
    @fines = patron_or_group.fines
    @fines_and_accruing = (@fines + accruing_checkouts).sort_by(&:sort_date)
  end

  def accruing_checkouts
    patron_or_group.checkouts.select(&:accruing?)
  end
end

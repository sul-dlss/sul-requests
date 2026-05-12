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
    @fines = fines
    @checkouts = checkouts
  end

  private

  def fines
    patron_or_group.fines
  end

  def checkouts
    patron_or_group.checkouts.sort_by { |c| c.sort_key(:due_date) }
  end
end

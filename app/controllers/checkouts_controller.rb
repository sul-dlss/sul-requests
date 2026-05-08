# frozen_string_literal: true

# Controller for the Checkouts page
class CheckoutsController < ApplicationController
  include FolioController

  before_action :authenticate_user!

  before_action :load_checkouts
  before_action :load_checkout, except: [:index]

  before_action :authorize_renew!, only: [:renew]

  # Render a list of checkouts for the patron
  #
  # GET /checkouts
  # GET /checkouts.json
  def index
    @checkouts = patron_or_group.checkouts.sort_by { |x| x.sort_key(:due_date) }
  end
end

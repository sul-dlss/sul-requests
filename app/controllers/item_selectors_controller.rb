# frozen_string_literal: true

# Loads an item selector with circulation data outside the initial page render.
class ItemSelectorsController < ApplicationController
  include FolioController

  def show
    @patron_request = PatronRequest.new(item_selector_params)
    FolioGraphqlClient.new.hydrate_circulation_status(items: @patron_request.selectable_items)
  end

  private

  def item_selector_params
    params.require(:instance_hrid)
    params.require(:origin_location_code)
    params.permit(:instance_hrid, :origin_location_code, requested_barcodes: [])
  end
end

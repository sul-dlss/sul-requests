# frozen_string_literal: true

###
#  Controller for handling the Circ Check app page for Access Services.
###
class CircCheckController < ApplicationController
  def index; end

  def show
    result = FolioGraphqlClient.new.circ_check(barcode: params[:barcode])
    @item = result.dig('data', 'items', 0)
  end
end

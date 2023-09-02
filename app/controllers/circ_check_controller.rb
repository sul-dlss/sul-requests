# frozen_string_literal: true

###
#  Controller for handling the Circ Check app page for Access Services.
###
class CircCheckController < ApplicationController
  layout false

  rescue_from StandardError, with: :render_error

  def index; end

  def show
    result = FolioGraphqlClient.new.circ_check(barcode: params[:barcode])
    @item = result&.dig('data', 'items', 0)
    raise "Barcode does not exist: #{params[:barcode]}" unless @item
  end

  def render_error(error)
    Honeybadger.notify(error)
    render 'error', locals: { error: }
  end
end

###
#  Controller concern to be mixed in to controllers that need to display modal content
###
module ModalLayout
  extend ActiveSupport::Concern

  included do
    layout :set_modal_layout
  end

  protected

  def set_modal_layout
    return unless params[:modal]

    'modal'
  end
end

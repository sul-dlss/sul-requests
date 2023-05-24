# frozen_string_literal: true

###
#  Module to mixin the permitted and required parameters for request controller actions
###
module RequestStrongParams
  def new_params
    params.permit(:modal)
    params.require(:origin)
    params.require(:item_id)
    params.require(:origin_location)

    params.permit(:origin, :item_id, :origin_location, :barcode)
  end

  def create_params
    params.permit(:email)
    params.permit(:modal)
    @create_params ||= params.require(:request).permit(:item_id, :origin, :origin_location, :destination,
                                                       :needed_date, :estimated_delivery,
                                                       :item_comment, :request_comment,
                                                       :authors, :page_range, :section_title, # scans
                                                       :proxy,
                                                       barcodes: {},
                                                       public_notes: {},
                                                       user_attributes: [:name, :email, :library_id])
  end

  def update_params
    params.permit(:email)
    params.permit(:modal)
    params.require(:request).permit(:needed_date)
  end
end
